//! One worker for app downloads and installers, in the order they were requested.

use std::collections::VecDeque;
use std::sync::{Arc, Mutex, PoisonError};

type Task = Box<dyn FnOnce() + Send>;

#[derive(Default)]
struct State {
    pending: VecDeque<(String, Task)>,
    running: bool,
}

#[derive(Default)]
pub(crate) struct JobQueue {
    state: Arc<Mutex<State>>,
}

impl JobQueue {
    pub fn push(&self, id: &str, task: impl FnOnce() + Send + 'static) {
        let mut state = self.state.lock().unwrap_or_else(PoisonError::into_inner);
        state.pending.push_back((id.to_string(), Box::new(task)));
        if state.running {
            return;
        }
        state.running = true;
        let state = self.state.clone();
        std::thread::spawn(move || {
            loop {
                let task = {
                    let mut state = state.lock().unwrap_or_else(PoisonError::into_inner);
                    match state.pending.pop_front() {
                        Some((_, task)) => task,
                        None => {
                            state.running = false;
                            return;
                        }
                    }
                };
                task();
            }
        });
    }

    /// Removes a waiting job. A job already taken by the worker uses its Stop control instead.
    pub fn cancel(&self, id: &str) -> bool {
        let mut state = self.state.lock().unwrap_or_else(PoisonError::into_inner);
        let Some(index) = state.pending.iter().position(|(app, _)| app == id) else { return false };
        state.pending.remove(index).is_some()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::mpsc;
    use std::time::Duration;

    #[test]
    fn jobs_wait_for_the_previous_job_to_finish_in_request_order() {
        let queue = JobQueue::default();
        let (events, received) = mpsc::channel();
        let (release, wait) = mpsc::channel();
        let first = events.clone();
        queue.push("first", move || {
            first.send("first started").unwrap();
            wait.recv_timeout(Duration::from_secs(5)).unwrap();
            first.send("first finished").unwrap();
        });
        assert_eq!(received.recv_timeout(Duration::from_secs(5)).unwrap(), "first started");
        for id in ["second", "third"] {
            let events = events.clone();
            queue.push(id, move || events.send(id).unwrap());
        }
        assert!(received.try_recv().is_err());
        release.send(()).unwrap();
        for event in ["first finished", "second", "third"] {
            assert_eq!(received.recv_timeout(Duration::from_secs(5)).unwrap(), event);
        }
    }

    #[test]
    fn a_cancelled_waiting_job_never_runs_and_the_remaining_jobs_continue() {
        let queue = JobQueue::default();
        let (events, received) = mpsc::channel();
        let (release, wait) = mpsc::channel();
        let first = events.clone();
        queue.push("active", move || {
            first.send("active").unwrap();
            wait.recv_timeout(Duration::from_secs(5)).unwrap();
        });
        assert_eq!(received.recv_timeout(Duration::from_secs(5)).unwrap(), "active");
        let skipped = events.clone();
        queue.push("cancelled", move || skipped.send("cancelled").unwrap());
        queue.push("next", move || events.send("next").unwrap());
        assert!(queue.cancel("cancelled"));
        assert!(!queue.cancel("active"));
        release.send(()).unwrap();
        assert_eq!(received.recv_timeout(Duration::from_secs(5)).unwrap(), "next");
        assert!(received.try_recv().is_err());
    }

    #[test]
    fn new_jobs_start_after_the_worker_has_drained_the_queue() {
        let queue = JobQueue::default();
        let (finished, received) = mpsc::channel();
        let first = finished.clone();
        queue.push("first", move || first.send(()).unwrap());
        received.recv_timeout(Duration::from_secs(5)).unwrap();
        let deadline = std::time::Instant::now() + Duration::from_secs(5);
        while queue.state.lock().unwrap().running {
            assert!(std::time::Instant::now() < deadline);
            std::thread::yield_now();
        }
        queue.push("next", move || finished.send(()).unwrap());
        received.recv_timeout(Duration::from_secs(5)).unwrap();
    }
}
