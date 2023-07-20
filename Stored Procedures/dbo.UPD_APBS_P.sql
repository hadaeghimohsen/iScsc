SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_APBS_P]
   @Code BIGINT,
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
   @Stat VARCHAR(3),
   @Lvrg_Valu REAL
AS 
BEGIN
   MERGE dbo.App_Base_Define T
   USING (SELECT @Code AS Code, @Titl_Desc AS Titl_Desc, @Enty_Name AS Enty_Name, @Ref_Code AS Ref_Code, @Rwno AS Rwno, @Numb AS NUMB, @Unit AS UNIT) S
   ON (T.Code = S.Code)
   WHEN MATCHED THEN
      UPDATE SET
         T.TITL_DESC = S.Titl_Desc,
         T.ENTY_NAME = S.Enty_Name,
         T.REF_CODE = S.Ref_Code,
         T.RWNO = S.Rwno,
         T.NUMB = s.NUMB,
         T.UNIT = s.UNIT,
         t.PRT1_TIME = @Prt1_Time,
         T.PRT2_TIME = @Prt2_Time,
         T.PRT3_TIME = @Prt3_Time,
         T.PRT4_TIME = @Prt4_Time,
         T.PRT5_TIME = @Prt5_Time,
         T.PRT6_TIME = @Prt6_Time,
         T.SEX_TYPE = @Sex_Type,
         T.COLR = @Colr,
         T.STAT = @Stat,
         T.LVRG_VALU = @Lvrg_Valu;
END 
GO
