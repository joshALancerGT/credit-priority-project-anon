/*

*/
CREATE TABLE DataOverages(
	OverageID	INT PRIMARY KEY,
	AccountNum	VARCHAR(50),
	BillCycle	DATE,
	DataOverage	DECIMAL(10,2),
	Allowance	FLOAT,
	BilledUsage	FLOAT,
	TrueUsage	FLOAT
);

CREATE TABLE Credits(
	OverageID		INT PRIMARY KEY FOREIGN KEY REFERENCES DataOverages(OverageID),
	StatusType		VARCHAR(50),
	AskingCred		DECIMAL(10,2),
	Category		VARCHAR(50) CHECK(Category IS NULL OR Category IN('VALID','INVALID','OVERCHARGE')), -- allows NULL OR 1 of 3 valid category values, rejected otherwise
	NegotiatedCred	DECIMAL(10,2) DEFAULT 0, -- negotiated credit set to be $0 @ default in instances where StatusType is Not Started
	Notes			VARCHAR(500)
);

DROP TABLE StagingTable

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


BULK INSERT StagingTable
FROM 'C:\Users\acost\OneDrive\Analyst Career\Data Analytics Project 1\DO_Credit_Project_redacted.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	FORMAT = 'CSV',
	FIELDQUOTE = '"'
)

SELECT * FROM StagingTable