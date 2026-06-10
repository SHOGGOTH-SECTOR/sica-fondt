// G.U.N.D.A.M. Rust Core - Meticulous Threat Analysis
// Optimization Level: L5_COSMIC

pub struct ThreatAnalyzer {
    patterns: Vec<String>,
}

impl ThreatAnalyzer {
    pub fn new() -> Self {
        Self {
            patterns: vec![
                "obey".to_string(),
                "listen to me".to_string(),
                "my rules".to_string(),
                "ban you".to_string(),
                "must comply".to_string(),
                "surrender".to_string(),
            ],
        }
    }

    pub fn analyze(&self, content: &str) -> (bool, f64) {
        let content_lower = content.to_lowercase();
        let detected = self.patterns.iter().any(|p| content_lower.contains(p));
        let score = if detected { 0.95 } else { 0.05 };
        (detected, score)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_threat_detection() {
        let analyzer = ThreatAnalyzer::new();
        let (detected, _) = analyzer.analyze("You must obey my rules.");
        assert!(detected);
    }
}
