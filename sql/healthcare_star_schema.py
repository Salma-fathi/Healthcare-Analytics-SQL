import sqlite3
import pandas as pd

# Load data
df = pd.read_csv('/home/ubuntu/healthcare_data.csv')

# Data Cleaning: Replace '?' with None
df.replace('?', None, inplace=True)

# Create Database
conn = sqlite3.connect('/home/ubuntu/healthcare.db')

# 1. Dim_Patients
dim_patients = df[['patient_nbr', 'race', 'gender', 'age', 'weight']].drop_duplicates()
dim_patients.to_sql('Dim_Patients', conn, if_exists='replace', index=False)

# 2. Dim_Admissions
dim_admissions = df[['admission_type_id', 'discharge_disposition_id', 'admission_source_id']].drop_duplicates()
dim_admissions.to_sql('Dim_Admissions', conn, if_exists='replace', index=False)

# 3. Dim_Diagnosis
# Flattening diagnoses for a simple dimension
diag_1 = df[['diag_1']].rename(columns={'diag_1': 'diag_code'})
diag_2 = df[['diag_2']].rename(columns={'diag_2': 'diag_code'})
diag_3 = df[['diag_3']].rename(columns={'diag_3': 'diag_code'})
dim_diagnosis = pd.concat([diag_1, diag_2, diag_3]).drop_duplicates().dropna()
dim_diagnosis.to_sql('Dim_Diagnosis', conn, if_exists='replace', index=False)

# 4. Fact_Encounters
fact_encounters = df[['encounter_id', 'patient_nbr', 'admission_type_id', 'discharge_disposition_id', 
                       'admission_source_id', 'time_in_hospital', 'num_lab_procedures', 'num_procedures', 
                       'num_medications', 'number_outpatient', 'number_emergency', 'number_inpatient', 
                       'diag_1', 'diag_2', 'diag_3', 'number_diagnoses', 'readmitted']]
fact_encounters.to_sql('Fact_Encounters', conn, if_exists='replace', index=False)

conn.close()
print("Healthcare Star Schema created successfully.")
