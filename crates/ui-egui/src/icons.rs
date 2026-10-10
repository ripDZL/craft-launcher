//! Bundled images: each Craft App's icon and the launcher's own.

use egui::ImageSource;

/// The 128 px icon of a Craft App.
pub fn app(id: &str) -> Option<ImageSource<'static>> {
    Some(match id {
        "photocraft" => egui::include_image!("../../../assets/app-icons/photocraft.png"),
        "vectorcraft" => egui::include_image!("../../../assets/app-icons/vectorcraft.png"),
        "filmcraft" => egui::include_image!("../../../assets/app-icons/filmcraft.png"),
        "lightcraft" => egui::include_image!("../../../assets/app-icons/lightcraft.png"),
        "pdfcraft" => egui::include_image!("../../../assets/app-icons/pdfcraft.png"),
        "effectcraft" => egui::include_image!("../../../assets/app-icons/effectcraft.png"),
        "designcraft" => egui::include_image!("../../../assets/app-icons/designcraft.png"),
        "wordcraft" => egui::include_image!("../../../assets/app-icons/wordcraft.png"),
        "deckcraft" => egui::include_image!("../../../assets/app-icons/deckcraft.png"),
        "gridcraft" => egui::include_image!("../../../assets/app-icons/gridcraft.png"),
        "cadcraft" => egui::include_image!("../../../assets/app-icons/cadcraft.png"),
        "soundcraft" => egui::include_image!("../../../assets/app-icons/soundcraft.png"),
        _ => return None,
    })
}

/// The fork's original geometric wordmark, in light/dark variants (MIT OR Apache-2.0).
pub fn suitedock_logo(dark_background: bool) -> ImageSource<'static> {
    if dark_background {
        egui::include_image!("../../../docs/brand/suitedock-logo-white.svg")
    } else {
        egui::include_image!("../../../docs/brand/suitedock-logo.svg")
    }
}

/// The original SuiteDock wordmark's width / height.
pub const SUITEDOCK_LOGO_ASPECT: f32 = 408.0 / 64.0;

/// An original generic pictogram for a community destination.
pub fn social(service: &str) -> Option<ImageSource<'static>> {
    Some(match service {
        "X" => egui::include_image!("../../../assets/social/x.svg"),
        "YouTube" => egui::include_image!("../../../assets/social/youtube.svg"),
        "TikTok" => egui::include_image!("../../../assets/social/tiktok.svg"),
        "Instagram" => egui::include_image!("../../../assets/social/instagram.svg"),
        "LinkedIn" => egui::include_image!("../../../assets/social/linkedin.svg"),
        _ => return None,
    })
}

/// The original SuiteDock dock/play mark (MIT OR Apache-2.0).
pub fn suitedock_mark() -> ImageSource<'static> {
    egui::include_image!("../../../docs/brand/suitedock-mark.svg")
}
