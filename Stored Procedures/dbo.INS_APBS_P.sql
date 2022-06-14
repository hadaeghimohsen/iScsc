SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_APBS_P]
   @Titl_Desc NVARCHAR(250),
   @Enty_Name VARCHAR(250),
   @Ref_Code BIGINT,
   @Rwno INT,
   @Numb FLOAT,
   @Unit SMALLINT,
   @Prt1_Time DATETIME,
   @Prt2_Time DATETIME,
   @Prt3_Time DATETIME,
   @Prt4_Time DATETIME,
   @Prt5_Time DATETIME,
   @Prt6_Time DATETIME,
   @Sex_Type VARCHAR(3),
   @Colr INT,
   @Stat VARCHAR(3)
AS 
BEGIN
   MERGE dbo.App_Base_Define T
   USING (SELECT @Titl_Desc AS Titl_Desc, @Enty_Name AS Enty_Name, @Ref_Code AS Ref_Code) S
   ON (T.TITL_DESC = S.Titl_Desc AND 
       T.ENTY_NAME = S.Enty_Name AND
       T.REF_CODE = S.Ref_Code)
   WHEN NOT MATCHED THEN
      INSERT (code, TITL_DESC, ENTY_NAME, REF_CODE, RWNO, NUMB, UNIT, PRT1_TIME, PRT2_TIME, PRT3_TIME, PRT4_TIME, PRT5_TIME, PRT6_TIME, SEX_TYPE, COLR, STAT)
      VALUES (0, s.Titl_Desc, s.Enty_Name, s.Ref_Code, @Rwno, @Numb, @Unit, @Prt1_Time, @Prt2_Time, @Prt3_Time, @Prt4_Time, @Prt5_Time, @Prt6_Time, @Sex_Type, @Colr, @Stat);
END 
GO
