import unittest
import sys
import os
import statistics

# Add lib to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../lib')))
import stats

class TestStats(unittest.TestCase):
    def setUp(self):
        self.data1 = [1, 2, 3, 4, 5]
        self.data2 = [10, 20, 30, 40, 50]
        self.skewed_data = [1, 1, 1, 1, 100]

    def test_calculate_stats(self):
        res = stats.calculate_stats(self.data1)
        # mean, median, stdev, min, max, p90, p95, p99, ci_l, ci_u
        self.assertEqual(res[0], 3.0) # Mean
        self.assertEqual(res[1], 3.0) # Median
        self.assertEqual(res[3], 1)   # Min
        self.assertEqual(res[4], 5)   # Max

    def test_check_normality(self):
        # Need at least 20 points for current implementation logic
        data = [i for i in range(25)]
        status, skew, kurt = stats.check_normality(data)
        self.assertEqual(status, "approximately_normal")

    def test_welchs_t_test(self):
        t, df, status = stats.welchs_t_test(self.data1, self.data2)
        self.assertEqual(status, "success")
        self.assertTrue(t < 0) # Data1 mean is much smaller than Data2

    def test_mann_whitney_u_test(self):
        u, z, status = stats.mann_whitney_u_test(self.data1, self.data2)
        self.assertEqual(status, "success")
        self.assertEqual(u, 0.0) # No overlap, U should be 0

    def test_pvalue_approximations(self):
        # Z-to-p
        self.assertEqual(stats.z_to_pvalue(2.0), 0.05)
        self.assertEqual(stats.z_to_pvalue(0.5), 0.50)
        # T-to-p (df > 30)
        self.assertEqual(stats.t_to_pvalue(2.0, 40), 0.05)

if __name__ == '__main__':
    unittest.main()
