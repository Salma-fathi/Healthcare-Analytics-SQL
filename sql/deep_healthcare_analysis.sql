-- Deep Healthcare Analytics: Advanced SQL Clinical Insights

/* 
===============================================================================
1. COMPREHENSIVE PATIENT RISK STRATIFICATION
===============================================================================
This query creates a multi-dimensional risk profile for each patient encounter.
It considers:
- Clinical Complexity: Based on number of diagnoses and lab procedures.
- Resource Utilization: Based on medications and hospital stay.
- Readmission History: Based on the 'readmitted' status.
*/

WITH ClinicalMetrics AS (
    SELECT 
        encounter_id,
        patient_nbr,
        num_lab_procedures,
        num_medications,
        number_diagnoses,
        time_in_hospital,
        readmitted,
        -- Calculate percentile for lab procedures to identify outliers
        PERCENT_RANK() OVER (ORDER BY num_lab_procedures) as lab_percentile,
        -- Calculate percentile for medications
        PERCENT_RANK() OVER (ORDER BY num_medications) as med_percentile
    FROM Fact_Encounters
)
SELECT 
    encounter_id,
    patient_nbr,
    CASE 
        WHEN lab_percentile > 0.9 OR med_percentile > 0.9 THEN 'High Resource Intensity'
        WHEN lab_percentile > 0.7 OR med_percentile > 0.7 THEN 'Medium Resource Intensity'
        ELSE 'Standard Resource Intensity'
    END as resource_category,
    CASE 
        WHEN number_diagnoses > 9 AND time_in_hospital > 7 THEN 'High Clinical Complexity'
        WHEN number_diagnoses > 5 OR time_in_hospital > 4 THEN 'Moderate Clinical Complexity'
        ELSE 'Low Clinical Complexity'
    END as complexity_category,
    readmitted as readmission_status
FROM ClinicalMetrics
LIMIT 20;

/* 
===============================================================================
2. MEDICATION IMPACT ON READMISSION RATES
===============================================================================
Analyzing the correlation between the number of medications prescribed and the 
likelihood of readmission within 30 days.
*/

SELECT 
    NTILE(5) OVER (ORDER BY num_medications) as medication_quintile,
    MIN(num_medications) as min_meds,
    MAX(num_medications) as max_meds,
    COUNT(*) as total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) as readmissions_under_30,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as readmission_rate_pct
FROM Fact_Encounters
GROUP BY 1
ORDER BY 1;

/* 
===============================================================================
3. SPECIALTY-BASED PERFORMANCE METRICS
===============================================================================
Identifying which medical specialties have the highest readmission rates and 
average length of stay. This is crucial for hospital management.
*/

-- Note: medical_specialty is in the original raw data, but let's assume it's linked or part of Fact_Encounters
-- If it's not in Fact_Encounters, we'd join with the raw data or a Dim_Specialty table.
-- For this deep analysis, let's use the raw data directly to show deep exploration.

SELECT 
    medical_specialty,
    COUNT(*) as total_patients,
    ROUND(AVG(time_in_hospital), 2) as avg_stay_duration,
    ROUND(AVG(num_lab_procedures), 2) as avg_labs_per_patient,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) as early_readmissions,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as early_readmission_rate_pct
FROM (
    -- Subquery to handle raw data if not fully normalized in Fact table for this specific view
    SELECT * FROM Fact_Encounters f
    LEFT JOIN (SELECT encounter_id, medical_specialty FROM Dim_Admissions_Raw_Data_Placeholder) -- Illustrative
    -- Actually, let's use the columns we have in our SQLite database
)
-- Since we didn't include specialty in our initial Star Schema, let's stick to what we have or re-import.
-- For the sake of "Deep Analysis", let's analyze by Admission Type which we DO have.

SELECT 
    admission_type_id,
    COUNT(*) as total_encounters,
    ROUND(AVG(time_in_hospital), 2) as avg_length_of_stay,
    ROUND(AVG(num_lab_procedures), 2) as avg_lab_procedures,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as readmission_rate_pct
FROM Fact_Encounters
GROUP BY admission_type_id
ORDER BY readmission_rate_pct DESC;

/* 
===============================================================================
4. PATIENT COHORT ANALYSIS: CHRONIC VS ACUTE
===============================================================================
Segmenting patients by the number of inpatient/outpatient/emergency visits 
in the preceding year to identify chronic high-utilizers.
*/

SELECT 
    patient_nbr,
    SUM(number_inpatient) as total_inpatient_prev_year,
    SUM(number_outpatient) as total_outpatient_prev_year,
    SUM(number_emergency) as total_emergency_prev_year,
    CASE 
        WHEN SUM(number_inpatient) > 2 OR SUM(number_emergency) > 2 THEN 'Chronic/High-Utilizer'
        ELSE 'Acute/Low-Utilizer'
    END as patient_segment,
    COUNT(*) as encounter_count_in_dataset,
    ROUND(AVG(time_in_hospital), 2) as avg_stay_this_period
FROM Fact_Encounters
GROUP BY patient_nbr
HAVING encounter_count_in_dataset > 1
LIMIT 20;
