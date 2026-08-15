# Data Overage Credit Priority/Classification Project

## Basic Overview
Built SQL Server to classify data overage charges (invalid/valid/overcharged) from raw account data collected via Excel Spreadsheet. In doing so, uncovered invalid & overcharges make up for nearly 60% of all data overage charges. Highlighted the success rate in which credits are received by category, further allowing analyst team to prioritize credits dependent on category once charges were categorized based upon True Data Usage vs Data Allowance & circumstantial notes. Displayed credit success rate, totaled charges, & credits obtained by category via inclusion of Tableau visualization to assist in prioritizing credit recovery efforts. 

## Business Context
Data Overage Charges are charges received if an account's users surpass the Data Allowance obtained by Account Analysts that are sent out via Bill Summary Invoices after an account's cycle. These are disputed whenever investigation reveal True Data Usage calculated (via Bill Summary) is lower than the Data Allowance, resulting in credit recovery process on INVALID/OVERCHARGED Bill Summaries. Prior to categorization, credit recovery process was initiated aimlessly whereas it is now systematically - focusing on INVALID charges as the highest priority. Contrary to management belief, VALID data charges are not the leading cause of high data charges resulting in the decrease of profit.

## Data / Material
- Source: Excel spreadsheet compiled from two analyst's anonymized accounts over the span of nearly a year.
- Schema: https://github.com/joshALancerGT/credit-priority-project-anon/blob/main/Credit%20Priority%20Schema.png
- Scope: Project limited to two analyst accounts. Project built upon 1:1 relationship (Overage-to-Credit) instead of modeling multi-attempt credit negotiation system

## Process / Phase
### Phase 1 - Schema Design
Made decision to split spreadsheet into two tables instead of one due to the belief in showcasing some skills with JOINs amongst databases. Collapsing spreadsheet into a single table diminishes skill showcasing.

### Phase 2 - Data Load
Staging table utilized in order to load Excel spreadsheet into MS SQL to then be split into two separate tables for the purpose of JOIN functions. Issues faced were primarily due to data type inconsistencies between tables / improper cast when transforming VARCHAR data types to INT data types.

### Phase 3 - Category Classification Logic
Categorizes data overage charges between VALID, INVALID, or OVERCHARGE based on determining factors pulled from various columns.
####Field Definition(s):
Allowance - data allowance during the cycle
TrueUsage - actual usage analyst(s) manually calculate to reveal difference between total usage calculated by carrier (BilledUsage) vs the actual total usage of all lines calculated utilizing via Invoice / Bill Summary
TrueGB - TrueUsage - Allowance reveals usage (GB) that should have actually been billed
TrueCharge - TrueUsage x $15/GB rounded to the value's ceiling. Reveals difference between what was charged vs what SHOULD have actually been charged
BilledGB - DataOverage/$15 displays the usage (GB) that was billed 
DataOVerage - charges received from the Invoice / Bill Summary 

Logic Determination:
INVALID - if the Data Allowance is greater than or equal to the True Usage AND the True Charge is 0 then it is automatically considered as an INVALID charge
OVERCHARGE - else if the TrueGB is less than the BilledGB AND the True Charge > 0 then it is classified as an OVERCHARGE
VALID - else if the TrueGB is greater than or equal to the BilledGB AND True Charge >= DataOverage then it is classified as a VALID charge

