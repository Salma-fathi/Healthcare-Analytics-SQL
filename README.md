# Healthcare Analytics: Deep SQL Insights

This project demonstrates advanced SQL capabilities for analyzing a real-world healthcare dataset, focusing on patient readmission, resource utilization, and clinical insights. It showcases data modeling, complex querying techniques, and actionable insights derived from healthcare data.

## Project Goal

The primary goal of this project is to leverage SQL for in-depth analysis of patient encounter data to:
*   Identify high-risk patient groups for readmission.
*   Understand patterns of resource utilization (medications, lab procedures).
*   Evaluate the impact of various factors on patient outcomes.
*   Provide data-driven insights to optimize healthcare operations and improve patient care.

## Dataset

The dataset used is the **Diabetic Hospital Readmission Dataset**, representing 10 years (1999-2008) of clinical care at 130 US hospitals. It includes over 50 features covering patient demographics, admission details, diagnoses, lab tests, medications, and readmission status.

**Source:** [Kaggle - Hospital Readmission Prediction](https://www.kaggle.com/datasets/vanpatangan/readmission-dataset) (Original source: UCI Machine Learning Repository)

## Methodology

1.  **Data Preparation:** Initial cleaning and handling of missing values (e.g., replacing "?" with NULL).
2.  **Data Modeling (Star Schema):** The raw data was transformed into a Star Schema within a SQLite database (`healthcare.db`) to facilitate efficient analytical querying. The schema includes:
    *   `Fact_Encounters`: Contains details of each patient encounter, linking to dimension tables.
    *   `Dim_Patients`: Patient demographics (patient_nbr, race, gender, age, weight).
    *   `Dim_Admissions`: Admission-related details (admission_type_id, discharge_disposition_id, admission_source_id).
    *   `Dim_Diagnosis`: Unique diagnosis codes (diag_code).
3.  **Advanced SQL Analysis:** A series of complex SQL queries were developed to extract insights, utilizing:
    *   Window Functions (`RANK()`, `PERCENT_RANK()`, `NTILE()`, `AVG() OVER()`).
    *   Common Table Expressions (CTEs) for modular and readable queries.
    *   Conditional Logic (`CASE` statements) for categorization and risk profiling.
    *   Aggregations (`COUNT()`, `SUM()`, `AVG()`) for summary statistics.

## Key SQL Analyses and Insights

### 1. Comprehensive Patient Risk Stratification

This query creates a multi-dimensional risk profile for each patient encounter, considering clinical complexity, resource utilization, and readmission history. It helps in identifying high-risk patients requiring immediate intervention.

**SQL Query:**
```sql
-- deep_healthcare_analysis.sql
SELECT 
    encounter_id,
    patient_nbr,
    age,
    readmitted,
    num_lab_procedures,
    RANK() OVER (PARTITION BY age ORDER BY num_lab_procedures DESC) as lab_rank_in_age_group,
    CASE 
        WHEN readmitted = '<30' THEN 'High Risk'
        WHEN readmitted = '>30' THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_profile
FROM Fact_Encounters f
JOIN Dim_Patients p ON f.patient_nbr = p.patient_nbr
LIMIT 20;
```

**Insights:** This analysis provides a granular view of patient risk based on readmission status and resource utilization within specific age brackets. It highlights that even within the same age group, patients can have significantly different risk profiles depending on their prior healthcare usage and readmission patterns.

### 2. Medication Impact on Readmission Rates

This analysis explores the correlation between the number of medications prescribed and the likelihood of readmission within 30 days, segmenting patients into quintiles based on medication count.

**SQL Query:**
```sql
-- deep_healthcare_analysis.sql
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
```

**Insights:** This analysis helps in understanding if a higher number of medications is associated with a higher readmission rate, which can inform medication management strategies and patient education initiatives.

### 3. Specialty-Based Performance Metrics (by Admission Type)

This query identifies performance metrics (average length of stay, lab procedures, and readmission rates) grouped by admission type. This is crucial for hospital management to assess efficiency and quality of care across different admission pathways.

**SQL Query:**
```sql
-- deep_healthcare_analysis.sql
SELECT 
    admission_type_id,
    COUNT(*) as total_encounters,
    ROUND(AVG(time_in_hospital), 2) as avg_length_of_stay,
    ROUND(AVG(num_lab_procedures), 2) as avg_lab_procedures,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as readmission_rate_pct
FROM Fact_Encounters
GROUP BY admission_type_id
ORDER BY readmission_rate_pct DESC;
```

**Insights:** By analyzing these metrics per admission type, hospitals can identify areas of excellence or concern, leading to targeted interventions to improve patient flow, resource allocation, and post-discharge follow-up protocols.

### 4. Patient Cohort Analysis: Chronic vs. Acute

This analysis segments patients based on their historical inpatient, outpatient, and emergency visits to identify chronic high-utilizers versus acute/low-utilizers. This helps in tailoring care plans and preventive strategies.

**SQL Query:**
```sql
-- deep_healthcare_analysis.sql
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
```

**Insights:** Understanding patient cohorts allows healthcare providers to develop proactive strategies for managing chronic conditions, reduce emergency visits for high-risk patients, and optimize long-term healthcare utilization.

## Project Structure

```
Healthcare-Analytics-SQL/
├── data/
│   └── healthcare_data.csv             # Raw dataset
├── sql/
│   └── healthcare_star_schema.py       # Python script to build Star Schema
│   └── deep_healthcare_analysis.sql    # Advanced SQL queries
├── README.md                           # Project overview and analysis details
└── healthcare.db                       # SQLite database (generated)
```

## How to Run the Project

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Salma-fathi/Healthcare-Analytics-SQL.git
    cd Healthcare-Analytics-SQL
    ```
2.  **Prepare the environment:** Ensure you have Python and SQLite installed.
3.  **Build the database:** Run the Python script to create the Star Schema database.
    ```bash
    python3 sql/healthcare_star_schema.py
    ```
4.  **Execute SQL queries:** You can execute the SQL queries using a SQLite client or a Python script.
    ```bash
    sqlite3 healthcare.db < sql/deep_healthcare_analysis.sql
    ```
    *Alternatively, use a Python script to run and display results (similar to `verify_advanced_queries.py` used during development).*

## Future Enhancements

*   **Power BI Dashboard:** Create an interactive Power BI dashboard to visualize these insights.
*   **Predictive Modeling:** Implement machine learning models (e.g., Logistic Regression) to predict readmission risk more accurately.
*   **Time-Series Analysis:** Incorporate more sophisticated time-series analysis for trends in patient admissions and discharges.
*   **Integration with EMR:** Simulate integration with Electronic Medical Records (EMR) for real-time data analysis.

## Author

Salma Mohammed
[LinkedIn](https://www.linkedin.com/in/salma-mohammed-3155a61a4)
[GitHub](https://github.com/Salma-fathi)
[Portfolio](https://salma-fathi.github.io/salma-portfolio/)
