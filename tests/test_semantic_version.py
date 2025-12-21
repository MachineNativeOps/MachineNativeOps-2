"""
Tests for SemanticVersion prerelease comparison

Tests that SemanticVersion comparison correctly handles prerelease versions
according to SemVer 2.0.0 specification.
"""

import unittest
from src.enterprise.reliability.versioning import SemanticVersion


class TestSemanticVersionComparison(unittest.TestCase):
    """Test SemanticVersion comparison methods"""

    def test_basic_version_comparison(self):
        """Test basic version comparison without prereleases"""
        v1_0_0 = SemanticVersion(1, 0, 0)
        v1_0_1 = SemanticVersion(1, 0, 1)
        v1_1_0 = SemanticVersion(1, 1, 0)
        v2_0_0 = SemanticVersion(2, 0, 0)

        self.assertLess(v1_0_0, v1_0_1)
        self.assertLess(v1_0_1, v1_1_0)
        self.assertLess(v1_1_0, v2_0_0)
        self.assertEqual(v1_0_0, SemanticVersion(1, 0, 0))

    def test_prerelease_lower_than_normal(self):
        """Test that prerelease versions have lower precedence than normal versions"""
        # 1.0.0-alpha < 1.0.0
        v_prerelease = SemanticVersion(1, 0, 0, prerelease="alpha")
        v_normal = SemanticVersion(1, 0, 0)

        self.assertLess(v_prerelease, v_normal)
        self.assertFalse(v_normal < v_prerelease)
        self.assertNotEqual(v_prerelease, v_normal)

    def test_prerelease_comparison_alpha_beta(self):
        """Test comparison of common prerelease versions"""
        v_alpha = SemanticVersion(1, 0, 0, prerelease="alpha")
        v_beta = SemanticVersion(1, 0, 0, prerelease="beta")
        v_rc = SemanticVersion(1, 0, 0, prerelease="rc")

        # Lexical ordering: alpha < beta < rc
        self.assertLess(v_alpha, v_beta)
        self.assertLess(v_beta, v_rc)
        self.assertLess(v_alpha, v_rc)

    def test_prerelease_numeric_comparison(self):
        """Test numeric prerelease identifier comparison"""
        v_alpha1 = SemanticVersion(1, 0, 0, prerelease="alpha.1")
        v_alpha2 = SemanticVersion(1, 0, 0, prerelease="alpha.2")
        v_alpha10 = SemanticVersion(1, 0, 0, prerelease="alpha.10")

        # Numeric comparison: 1 < 2 < 10
        self.assertLess(v_alpha1, v_alpha2)
        self.assertLess(v_alpha2, v_alpha10)
        self.assertLess(v_alpha1, v_alpha10)

    def test_prerelease_mixed_numeric_alpha(self):
        """Test mixed numeric and alphanumeric identifiers"""
        v_alpha = SemanticVersion(1, 0, 0, prerelease="alpha")
        v_alpha1 = SemanticVersion(1, 0, 0, prerelease="alpha.1")

        # More identifiers = higher precedence
        self.assertLess(v_alpha, v_alpha1)

    def test_numeric_lower_than_alphanumeric(self):
        """Test that numeric identifiers have lower precedence than alphanumeric"""
        v_1 = SemanticVersion(1, 0, 0, prerelease="1")
        v_alpha = SemanticVersion(1, 0, 0, prerelease="alpha")

        # Numeric < alphanumeric
        self.assertLess(v_1, v_alpha)

    def test_semver_spec_example(self):
        """Test the example from SemVer 2.0.0 spec"""
        # From SemVer spec: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta
        # < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
        versions = [
            SemanticVersion(1, 0, 0, prerelease="alpha"),
            SemanticVersion(1, 0, 0, prerelease="alpha.1"),
            SemanticVersion(1, 0, 0, prerelease="alpha.beta"),
            SemanticVersion(1, 0, 0, prerelease="beta"),
            SemanticVersion(1, 0, 0, prerelease="beta.2"),
            SemanticVersion(1, 0, 0, prerelease="beta.11"),
            SemanticVersion(1, 0, 0, prerelease="rc.1"),
            SemanticVersion(1, 0, 0),
        ]

        # Verify each version is less than the next
        for i in range(len(versions) - 1):
            self.assertLess(versions[i], versions[i + 1],
                f"{versions[i]} should be < {versions[i + 1]}")

    def test_equality_with_prerelease(self):
        """Test equality comparison with prereleases"""
        v1 = SemanticVersion(1, 0, 0, prerelease="alpha")
        v2 = SemanticVersion(1, 0, 0, prerelease="alpha")
        v3 = SemanticVersion(1, 0, 0, prerelease="beta")
        v4 = SemanticVersion(1, 0, 0)

        self.assertEqual(v1, v2)
        self.assertNotEqual(v1, v3)
        self.assertNotEqual(v1, v4)

    def test_total_ordering_methods(self):
        """Test that @total_ordering generates correct comparison methods"""
        v_pre = SemanticVersion(1, 0, 0, prerelease="alpha")
        v_normal = SemanticVersion(1, 0, 0)

        # Test >, >=, <=
        self.assertGreater(v_normal, v_pre)
        self.assertGreaterEqual(v_normal, v_pre)
        self.assertLessEqual(v_pre, v_normal)
        self.assertFalse(v_pre > v_normal)
        self.assertFalse(v_pre >= v_normal)
        self.assertFalse(v_normal <= v_pre)

    def test_parse_and_compare(self):
        """Test parsing version strings and comparing them"""
        v1 = SemanticVersion.parse("1.0.0-alpha")
        v2 = SemanticVersion.parse("1.0.0")

        self.assertLess(v1, v2)
        self.assertEqual(v1.prerelease, "alpha")
        self.assertEqual(v2.prerelease, "")

    def test_build_metadata_ignored_in_comparison(self):
        """Test that build metadata is ignored in version comparison"""
        v1 = SemanticVersion(1, 0, 0, prerelease="alpha", build="001")
        v2 = SemanticVersion(1, 0, 0, prerelease="alpha", build="002")

        # Build metadata should not affect comparison
        self.assertEqual(v1, v2)
        self.assertFalse(v1 < v2)
        self.assertFalse(v2 < v1)


if __name__ == "__main__":
    unittest.main()
