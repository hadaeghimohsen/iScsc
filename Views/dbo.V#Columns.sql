SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[V#Columns] AS
SELECT 
     st.object_id AS OBJC_ID,
     st.name TABL_NAME,
     sc.column_id AS CLMN_ID,
     sc.name CLMN_NAME,
     sep.value [DESC],
     isc.DATA_TYPE
 FROM sys.tables st
 INNER JOIN sys.columns sc ON st.object_id = sc.object_id
 INNER JOIN INFORMATION_SCHEMA.COLUMNS isc ON (isc.TABLE_NAME = st.name AND isc.COLUMN_NAME = sc.name)
 LEFT JOIN sys.extended_properties sep ON st.object_id = sep.major_id
                                      AND sc.column_id = sep.minor_id
                                      AND sep.name = 'MS_Description';

GO
