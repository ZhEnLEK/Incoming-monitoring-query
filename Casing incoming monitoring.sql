
SELECT * 
INTO #TEMP1
FROM OPENQUERY (KLCONNECT, 
 ' SELECT D.[Form_Type]
,D.[Collector_Name]
	   ,C.Batch_No
      ,C.Seq_No 
      ,C.[Tyre_Serial_Number]
	  ,C.[Tyre_Size]
	  ,C.[Tyre_Brand]
	  ,C.[Retread_Brand]
	  ,C.[Retread_Pattern]
	  ,D.[Date_Collected] 
	  ,C.Date_Unloaded 
      ,D.Customer_Name
	  	  
 FROM  KLConnectDev.dbo.[KLConnect LOG$Collection Detail] C
   
  RIGHT JOIN KLConnectDev.dbo.[KLConnect LOG$Collection Header] D
  ON C.Batch_No = D.Batch_No
  WHERE  D.[Date_Collected] > DATEADD(YEAR, -1, GETDATE()) '
  )

  SELECT  IDENTITY( int ) AS ID
,A.Is_Active AS 'A IS ACTIVE'
,B.Is_Active AS 'B IS ACTIVE'
,C.Form_Type
,C.Collector_Name
,C.Batch_No
,C.Batch_No + '-'+ C.Seq_No AS 'RONUMBER'
 ,C.[Tyre_Serial_Number]
	  ,C.[Tyre_Size]
	  ,C.[Tyre_Brand]
	  ,C.[Retread_Brand]
	  ,C.[Retread_Pattern]
	  ,C.[Date_Collected] AS 'COLLECTED'
	  ,C.Date_Unloaded AS 'UNLOADED'
      ,A.[Date_Created] AS 'GRADED'
,B.Date_Created AS 'PIO'
, CAST(E.IsReject AS int ) AS 'REJECTED'
,C.Customer_Name
INTO #TEMP2
FROM #TEMP1 C
LEFT JOIN [klconnect_retread].[HealthCheck].[GradedCasing] A
 ON C.Batch_No + '-'+ C.Seq_No = A.RONumber
  LEFT JOIN [klconnect_retread].[PIO].[OrganizedCasing] B
  ON A.RONumber = B.RONumber
  LEFT JOIN [klconnect_retread].[Logistic].[PutAsideCasing] E
  ON A.RONumber = E.RONumber

SELECT Form_Type, Batch_No, COUNT(COLLECTED) AS 'COLLECTED', COUNT(UNLOADED) AS UNLOADED, COUNT(GRADED) AS GRADED, COUNT(PIO) AS 'PIO' INTO #TEMP3  FROM #TEMP2 
GROUP BY Form_Type, Batch_No 

SELECT * INTO #TEMP4 FROM #TEMP3 WHERE (Form_Type = 'RO' AND COLLECTED = PIO) -->table for filtering later  
OR (Form_Type = 'CTF' AND COLLECTED = UNLOADED)
OR (Form_Type = 'TO' AND COLLECTED = UNLOADED)

DELETE FROM #TEMP2  --> filter out the batch nos from #TEMP4
WHERE Batch_No IN (select Batch_No from #TEMP4) 

SELECT * INTO #TEMP5 FROM #TEMP2 --> table of all duplicates
WHERE [A IS ACTIVE] = 0 OR [B IS ACTIVE] = 0  

DELETE FROM #TEMP2 --> REMOVE DUPLICATES
WHERE RONUMBER IN (SELECT DISTINCT(RONUMBER) FROM #TEMP5) 


SELECT 
Form_Type
,Collector_Name
,Batch_No
,RONUMBER
,Tyre_Serial_Number 
,Tyre_Size
,Tyre_Brand
,Retread_Brand
,Retread_Pattern
,COLLECTED
,UNLOADED
,GRADED
,PIO
,REJECTED
,Customer_Name

FROM #TEMP2

order by COLLECTED DESC, RONUMBER