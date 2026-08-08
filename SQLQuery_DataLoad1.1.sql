-- Create's table to be split after staging data from spreadsheet into Staging/Temp Table 
CREATE TABLE DataOverages(
	OverageID	INT PRIMARY KEY,
	AccountNum	VARCHAR(50),
	BillCycle	DATE,
	DataOverage	DECIMAL(10,2),
	Allowance	FLOAT,
	BilledUsage	FLOAT,
	TrueUsage	FLOAT
);

-- Create's table to be split after staging data from spreadsheet into Staging/Temp Table 
CREATE TABLE Credits(
	OverageID		INT PRIMARY KEY FOREIGN KEY REFERENCES DataOverages(OverageID),
	StatusType		VARCHAR(50),
	AskingCred		DECIMAL(10,2),
	Category		VARCHAR(50) CHECK(Category IS NULL OR Category IN('VALID','INVALID','OVERCHARGE')), -- allows NULL OR 1 of 3 valid category values, rejected otherwise
	NegotiatedCred	DECIMAL(10,2) DEFAULT 0, -- negotiated credit set to be $0 @ default in instances where StatusType is Not Started
	Notes			VARCHAR(500)
);

-- used after sequence error discovered when importing raw data from spreadsheet to StagingTable
-- DROP TABLE StagingTable 

-- Staging Table (Temp Table)
CREATE TABLE StagingTable(
	AccountNum		VARCHAR(50),
	OverageID		VARCHAR(50),
	StatusType		VARCHAR(50),
	BillCycle		DATE,
	DataOverage		VARCHAR(50),
	Allowance		FLOAT,
	BilledUsage		FLOAT,
	TrueUsage		FLOAT,
	AskingCred		VARCHAR(50),
	Category		VARCHAR(50) CHECK(Category IS NULL OR Category IN('VALID','INVALID','OVERCHARGE')), -- allows NULL OR 1 of 3 valid category values, rejected otherwise
	NegotiatedCred	VARCHAR(50) DEFAULT 0, -- negotiated credit set to be $0 @ default in instances where StatusType is Not Started
	Notes			VARCHAR(500)
);

-- loads exported CSV into staging / place holder table
BULK INSERT StagingTable
FROM 'C:\Users\acost\OneDrive\Analyst Career\Data Analytics Project 1\DO_Credit_Project_redacted.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	FORMAT = 'CSV',
	FIELDQUOTE = '"'
)

--	verifies CSV loaded into staging table successfully 
--	SELECT * FROM StagingTable
-- 	SELECT * FROM DataOverages
-- 	SELECT * FROM Credits

INSERT INTO DataOverages(OverageID,AccountNum,BillCycle,DataOverage,Allowance,BilledUsage,TrueUsage)
SELECT
	OverageID,
	AccountNum,
	BillCycle,
	CAST(CAST(DataOverage AS MONEY) AS DECIMAL(10,2)),
	Allowance,
	BilledUsage,
	TrueUsage
FROM StagingTable

INSERT INTO Credits(OverageID,StatusType,AskingCred,Category,NegotiatedCred,Notes)
SELECT
	OverageID,
	StatusType,
	CAST(CAST(AskingCred AS MONEY) AS DECIMAL(10,2)),
	Category,
	CAST(CAST(NegotiatedCred AS MONEY) AS DECIMAL(10,2)),
	Notes
FROM StagingTable
