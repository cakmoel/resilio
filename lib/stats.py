#!/usr/bin/env python3
import sys
import math
import statistics
import json

def calculate_stats(values):
    """Returns basic stats for a sequence of numbers."""
    if not values:
        return [0] * 10
    
    n = len(values)
    mean = statistics.mean(values)
    median = statistics.median(values)
    
    if n > 1:
        stdev = statistics.stdev(values)
        variance = statistics.variance(values)
    else:
        stdev = 0
        variance = 0
        
    min_val = min(values)
    max_val = max(values)
    
    sorted_vals = sorted(values)
    p90 = sorted_vals[int(0.90 * (n - 1))]
    p95 = sorted_vals[int(0.95 * (n - 1))]
    p99 = sorted_vals[int(0.99 * (n - 1))]
    
    # 95% Confidence Interval
    confidence_margin = 1.96 * (stdev / math.sqrt(n)) if n > 0 else 0
    ci_lower = mean - confidence_margin
    ci_upper = mean + confidence_margin
    
    return [mean, median, stdev, min_val, max_val, p90, p95, p99, ci_lower, ci_upper]

def check_normality(values):
    """Returns normality status and skew/kurtosis (D'Agostino's approach)."""
    n = len(values)
    if n < 20:
        return "insufficient_data", 0, 0
    
    mean = statistics.mean(values)
    stdev = statistics.stdev(values)
    if stdev == 0:
        return "zero_variance", 0, 0
    
    z_scores = [(x - mean) / stdev for x in values]
    skewness = sum(z**3 for z in z_scores) / n
    # Excess kurtosis
    kurtosis = (sum(z**4 for z in z_scores) / n) - 3
    
    is_normal = abs(skewness) <= 1.0 and abs(kurtosis) <= 2.0
    status = "approximately_normal" if is_normal else "non_normal"
    return status, skewness, kurtosis

def welchs_t_test(v1, v2):
    """Performs Welch's t-test for unequal variances."""
    n1, n2 = len(v1), len(v2)
    if n1 < 2 or n2 < 2:
        return 0, 0, 0, "insufficient_data"
    
    m1, m2 = statistics.mean(v1), statistics.mean(v2)
    s1_sq, s2_sq = statistics.variance(v1), statistics.variance(v2)
    
    se = math.sqrt((s1_sq / n1) + (s2_sq / n2))
    if se == 0:
        return 0, 0, 999, "zero_variance"
    
    t_stat = (m1 - m2) / se
    
    # Degrees of freedom (Welch-Satterthwaite)
    num = (s1_sq/n1 + s2_sq/n2)**2
    den = (s1_sq/n1)**2 / (n1-1) + (s2_sq/n2)**2 / (n2-1)
    df = num / den if den > 0 else 30
    
    return t_stat, df, "success"

def mann_whitney_u_test(v1, v2):
    """Performs Mann-Whitney U test with O(N log N) rank calculation."""
    n1, n2 = len(v1), len(v2)
    if n1 < 3 or n2 < 3:
        return 0, 0, "insufficient_data"
    
    combined = sorted([(v, 1) for v in v1] + [(v, 2) for v in v2])
    
    # Calculate ranks with tie handling
    ranks = [0] * (n1 + n2)
    i = 0
    while i < len(combined):
        j = i
        while j < len(combined) and combined[j][0] == combined[i][0]:
            j += 1
        
        # Mean rank for the tie group
        avg_rank = (i + 1 + j) / 2.0
        for k in range(i, j):
            # Extract original group and assign rank
            # Note: we don't need to assign back to specific index if we just sum
            pass
        
        # Optimization: sum ranks directly
        # This part requires tracking which value belongs to which group
        # Let's adjust the combined strategy
        i = j

    # Re-calculating R1 properly
    combined = sorted([(v, 1) for v in v1] + [(v, 2) for v in v2])
    r1_sum = 0
    i = 0
    while i < len(combined):
        j = i
        while j < len(combined) and combined[j][0] == combined[i][0]:
            j += 1
        avg_rank = (i + 1 + j) / 2.0
        for k in range(i, j):
            if combined[k][1] == 1:
                r1_sum += avg_rank
        i = j
        
    u1 = r1_sum - (n1 * (n1 + 1)) / 2
    u2 = (n1 * n2) - u1
    u_stat = min(u1, u2)
    
    # Large sample approximation
    mu_u = (n1 * n2) / 2
    sigma_u = math.sqrt((n1 * n2 * (n1 + n2 + 1)) / 12)
    
    if sigma_u == 0:
        return u_stat, 0, "zero_variance"
        
    z_score = (u_stat - mu_u) / sigma_u
    # Simplified p-value approximation for the purpose of the report
    # Real implementation would use error function, but we match the script's logic
    return u_stat, z_score, "success"

def calculate_cohens_d(m1, m2, s1_sq, s2_sq, n1, n2):
    pooled_var = (((n1 - 1) * s1_sq) + ((n2 - 1) * s2_sq)) / (n1 + n2 - 2)
    pooled_sd = math.sqrt(pooled_var)
    return (m1 - m2) / pooled_sd if pooled_sd > 0 else 0

def calculate_rank_biserial(u_stat, n1, n2):
    return 1 - (2 * u_stat) / (n1 * n2)

def interpret_effect_size(effect):
    abs_e = abs(effect)
    if abs_e < 0.2: return "negligible"
    if abs_e < 0.5: return "small"
    if abs_e < 0.8: return "medium"
    return "large"

def t_to_pvalue(t, df):
    # Simplified approximation matching Bash version's bins
    abs_t = abs(t)
    if df > 30:
        if abs_t > 3.5: return 0.001
        if abs_t > 2.576: return 0.01
        if abs_t > 1.96: return 0.05
        if abs_t > 1.645: return 0.10
        return 0.20
    else:
        if abs_t > 3.0: return 0.01
        if abs_t > 2.0: return 0.05
        return 0.20

def z_to_pvalue(z):
    # Simplified approximation matching Bash version
    abs_z = abs(z)
    if abs_z > 3.291: return 0.001
    if abs_z > 2.576: return 0.01
    if abs_z > 1.96: return 0.05
    if abs_z > 1.645: return 0.10
    if abs_z > 1.28: return 0.20
    return 0.50

def main():
    if len(sys.argv) < 2:
        print("Usage: stats.py <command> <args...>")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    try:
        if cmd == "calculate_statistics":
            data = [float(x) for x in sys.stdin.read().split()]
            results = calculate_stats(data)
            # Add variance at the end for internal use
            v = statistics.variance(data) if len(data) > 1 else 0
            results.append(v)
            print("|".join(f"{x:.6f}" if isinstance(x, float) else str(x) for x in results))
            
        elif cmd == "check_normality":
            data = [float(x) for x in sys.stdin.read().split()]
            status, skew, kurt = check_normality(data)
            print(f"{status}|skew={skew:.4f}|kurt={kurt:.4f}")
            
        elif cmd == "hypothesis_test":
            raw_input = sys.stdin.read().split("---")
            v1 = [float(x) for x in raw_input[0].split()]
            v2 = [float(x) for x in raw_input[1].split()]
            
            n1, n2 = len(v1), len(v2)
            s1_status, s1_skew, s1_kurt = check_normality(v1)
            s2_status, s2_skew, s2_kurt = check_normality(v2)
            
            if s1_status == "approximately_normal" and s2_status == "approximately_normal":
                t, df, status = welchs_t_test(v1, v2)
                p = t_to_pvalue(t, df)
                m1, m2 = statistics.mean(v1), statistics.mean(v2)
                v1_var, v2_var = statistics.variance(v1), statistics.variance(v2)
                effect = calculate_cohens_d(m1, m2, v1_var, v2_var, n1, n2)
                print(f"welch|{t:.6f}|{df:.6f}|{p:.6f}|{status}|{effect:.6f}|{s1_status}|{s2_status}")
            else:
                u, z, status = mann_whitney_u_test(v1, v2)
                p = z_to_pvalue(z)
                effect = calculate_rank_biserial(u, n1, n2)
                print(f"mann_whitney|{u:.6f}|{z:.6f}|{p:.6f}|{status}|{effect:.6f}|{s1_status}|{s2_status}")
                
    except Exception as e:
        print(f"ERROR|{str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
