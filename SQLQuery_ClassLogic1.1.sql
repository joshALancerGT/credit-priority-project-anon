/*
DROP TABLE DataOverages
DROP TABLE Credits

CREATE TABLE DataOverages(
	OverageID	VARCHAR(10) PRIMARY KEY,
	AccountNum	VARCHAR(50),
	BillCycle	DATE,
	DataOverage	DECIMAL(10,2),
	Allowance	FLOAT,
	BilledUsage	FLOAT,
	TrueUsage	FLOAT
);

CREATE TABLE Credits(
	OverageID		VARCHAR(10) PRIMARY KEY FOREIGN KEY REFERENCES DataOverages(OverageID),
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

-- SELECT * FROM StagingTable
-- SELECT * FROM DataOverages
-- SELECT * FROM Credits

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

*/
-- SELECT * FROM DataOverages
-- SELECT * FROM Credits

-- CLASSIFICATION LOGIC
-- categorizes INVALID charges based on data allowance >= true usage
-- temp usage, only validates INVALID charges

/*
SELECT 
	do.AccountNum,
	do.OverageID,
	do.DataOverage,
	do.Allowance,
	do.TrueUsage,
	c.AskingCred,
	CASE 
		WHEN do.Allowance >= do.TrueUsage THEN 'INVALID'
	END Category,
	c.NegotiatedCred
FROM DataOverages do
JOIN Credits c
	ON c.OverageID = do.OverageID
ORDER BY Category DESC
*/

-- categorizes INVALID, OVERCHARGES, & VALID charges based on data allowance >= true usage
SELECT
	AccountNum,
	OverageID,
	DataOverage,
	Allowance,
	TrueUsage,
	AskingCred,
	NegotiatedCred,
	CASE -- key classification logic
		WHEN Allowance >= TrueUsage AND TrueCharge = 0 THEN 'INVALID'
		WHEN TrueGB < BilledGB AND TrueCharge > 0 THEN 'OVERCHARGED'
		WHEN TrueGB >= BilledGB AND TrueCharge >= DataOverage THEN 'VALID' -- applied logic instead of utilizing ELSE to confirm correct logic
		ELSE NULL -- serves as safety net in case any data was not classified successfully
	END Category
FROM(
	SELECT 
		do.AccountNum,
		do.OverageID,
		do.DataOverage,
		do.Allowance,
		do.TrueUsage,
		c.AskingCred,
		CEILING(do.DataOverage/15) AS BilledGB,
		CASE
			WHEN c.AskingCred = do.DataOverage THEN 0
			ELSE CEILING(do.TrueUsage - do.Allowance)
		END TrueGB, -- column created for key classification logic
		CASE
			WHEN c.AskingCred = do.DataOverage THEN 0
			ELSE CEILING(do.TrueUsage - do.Allowance)*15
		END TrueCharge, -- column created for key classification logic
		c.NegotiatedCred
	FROM DataOverages do
	JOIN Credits c
		ON c.OverageID = do.OverageID
	)SubQ
ORDER BY Category


-- TRACKING COUNT BETWEEN EACH CATEGORY
-- allows count of category type after classification logic
SELECT 
	Category,
	COUNT(Category) CategoryCount
FROM(
	SELECT
		*,
		CASE 
			WHEN Allowance >= TrueUsage AND TrueCharge = 0 THEN 'INVALID'
			WHEN TrueGB < BilledGB AND TrueCharge > 0 THEN 'OVERCHARGED'
			WHEN TrueGB >= BilledGB AND TrueCharge >= DataOverage THEN 'VALID'
			ELSE NULL
		END Category
	FROM(
		SELECT 
			do.AccountNum,
			do.OverageID,
			do.DataOverage,
			do.Allowance,
			do.TrueUsage,
			c.AskingCred,
			CEILING(do.DataOverage/15) AS BilledGB,
			CASE
				WHEN c.AskingCred = do.DataOverage THEN 0
				ELSE CEILING(do.TrueUsage - do.Allowance)
			END TrueGB,
			CASE
				WHEN c.AskingCred = do.DataOverage THEN 0
				ELSE CEILING(do.TrueUsage - do.Allowance)*15
			END TrueCharge,
			c.NegotiatedCred
		FROM DataOverages do
		JOIN Credits c
			ON c.OverageID = do.OverageID
		)SubQ
	)SubQ2
GROUP BY Category
---------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- UPDATING Credits category column to make aggregation simpler
UPDATE c
SET c.Category = cc.Category
FROM Credits c
JOIN(
	SELECT
		AccountNum,
		OverageID,
		DataOverage,
		Allowance,
		TrueUsage,
		AskingCred,
		NegotiatedCred,
		CASE -- key classification logic
			WHEN Allowance >= TrueUsage AND TrueCharge = 0 THEN 'INVALID'
			WHEN TrueGB < BilledGB AND TrueCharge > 0 THEN 'OVERCHARGE'
			WHEN TrueGB >= BilledGB AND TrueCharge >= DataOverage THEN 'VALID'
			ELSE NULL
		END Category
	FROM(
		SELECT 
			do.AccountNum,
			do.OverageID,
			do.DataOverage,
			do.Allowance,
			do.TrueUsage,
			c.AskingCred,
			CEILING(do.DataOverage/15) AS BilledGB,
			CASE
				WHEN do.TrueUsage <= do.Allowance THEN 0
				ELSE CEILING(do.TrueUsage - do.Allowance)
			END TrueGB, -- column created for key classification logic
			CASE
				WHEN do.TrueUsage <= do.Allowance THEN 0
				ELSE CEILING(do.TrueUsage - do.Allowance)*15
			END TrueCharge, -- column created for key classification logic
			c.NegotiatedCred
		FROM DataOverages do
		JOIN Credits c
			ON c.OverageID = do.OverageID
		)SubQ
	) cc 
ON cc.OverageID = c.OverageID

SELECT * FROM Credits -- checks to see if update was done successfully

-- TO DO'S
-- create a new column after true charge displaying the amount of overage charge that was charged incorrectly
-- step can be pushed to aggregation phase
