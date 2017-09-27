SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_FGPB_P]
	-- Add the parameters for the stored procedure here
	@Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
	@File_No   BIGINT,
	@Dise_Code BIGINT,
	@Mtod_Code BIGINT,
	@Ctgy_Code BIGINT,
	@Club_Code BIGINT,
	@Rqro_Rqst_Rqid BIGINT,
	@Rqro_Rwno smallint,
	@Rect_Code VARCHAR(3),
	@Frst_Name NVARCHAR(250),
	@Last_Name NVARCHAR(250),
	@Fath_Name NVARCHAR(250),
	@Sex_Type  VARCHAR(3),
	@Natl_Code VARCHAR(10),
	@Brth_Date DATE,
	@Cell_Phon VARCHAR(11),
	@Tell_Phon VARCHAR(11),
	@Coch_Deg  VARCHAR(3),
	@Gudg_Deg  VARCHAR(3),
	@Glob_Code VARCHAR(20),
	@Type      VARCHAR(3),
	@Post_Adrs NVARCHAR(1000),
	@Emal_Adrs NVARCHAR(250),
	@Insr_Numb VARCHAR(10),
	@Insr_Date DATE,
	@Educ_Deg VARCHAR(3),
	@Coch_File_No BIGINT,
	@Cbmt_Code BIGINT,
	@Day_Type  VARCHAR(3),
	@Attn_Time TIME(7),
	@Coch_Crtf_Date DATE,
	@Calc_Expn_Type VARCHAR(3),
	@Actv_Tag  VARCHAR(3),
	@Blod_Grop VARCHAR(3),
	@Fngr_Prnt VARCHAR(20),
   @SUNT_BUNT_DEPT_ORGN_CODE VARCHAR(2),
	@SUNT_BUNT_DEPT_CODE VARCHAR(2),
	@SUNT_BUNT_CODE VARCHAR(2),
	@SUNT_CODE VARCHAR(4),
	@CORD_X REAL,
	@CORD_Y REAL,
	@Most_Debt_Clng BIGINT,
	@Serv_No NVARCHAR(50),
   @Brth_Plac NVARCHAR(100),
	@Issu_Plac NVARCHAR(100),
	@Fath_Work NVARCHAR(150),
	@Hist_Desc NVARCHAR(500),
	@Intr_File_No BIGINT,
	@Cntr_Code BIGINT,
	@Dpst_Acnt_Slry_Bank NVARCHAR(50),
	@Dpst_Acnt_Slry VARCHAR(50)
AS
BEGIN
   IF @Intr_File_No = 0 SET @Intr_File_No = NULL
   IF @Cntr_Code = 0 SET @Cntr_Code = NULL;
	
	UPDATE [dbo].[Fighter_Public]
	   SET [REGN_PRVN_CODE] = @Prvn_Code
	      ,[REGN_CODE] = @Regn_Code
	      ,[DISE_CODE] = @Dise_Code
	      ,[MTOD_CODE] = @Mtod_Code
	      ,[CTGY_CODE] = @Ctgy_Code
         ,[CLUB_CODE] = @Club_Code
         ,[RECT_CODE] = @Rect_Code
         ,[FRST_NAME] = @Frst_Name
         ,[LAST_NAME] = @Last_Name
         ,[FATH_NAME] = @Fath_Name
         ,[SEX_TYPE] = @Sex_Type
         ,[NATL_CODE] = @Natl_Code
         ,[BRTH_DATE] = @Brth_Date
         ,[CELL_PHON] = @Cell_Phon
         ,[TELL_PHON] = @Tell_Phon
         ,[COCH_DEG] = @Coch_Deg
         ,[GUDG_DEG] = @Gudg_Deg
         ,[GLOB_CODE] = @Glob_Code
         ,[TYPE] = @Type
         ,[POST_ADRS] = @Post_Adrs
         ,[EMAL_ADRS] = @Emal_Adrs
         ,[INSR_NUMB] = @Insr_Numb
         ,[INSR_DATE] = @Insr_Date
         ,[EDUC_DEG] = @Educ_Deg
         ,[COCH_FILE_NO] = @Coch_File_No
         ,[CBMT_CODE] = @Cbmt_Code
         ,[DAY_TYPE] = @Day_Type
         ,[ATTN_TIME] = @Attn_Time 
         ,[COCH_CRTF_DATE] = @Coch_Crtf_Date
         ,[CALC_EXPN_TYPE] = @Calc_Expn_Type
         ,[ACTV_TAG] = @Actv_Tag
         ,[BLOD_GROP] = @Blod_Grop
         ,[FNGR_PRNT] = @Fngr_Prnt
         ,[SUNT_BUNT_DEPT_ORGN_CODE] = @SUNT_BUNT_DEPT_ORGN_CODE
         ,[SUNT_BUNT_DEPT_CODE] = @SUNT_BUNT_DEPT_CODE
         ,[SUNT_BUNT_CODE] = @SUNT_BUNT_CODE
         ,[SUNT_CODE] = @SUNT_CODE
         ,[CORD_X] = @CORD_X
         ,[CORD_Y] = @CORD_Y
         ,[MOST_DEBT_CLNG] = @Most_Debt_Clng
         ,[SERV_NO] = @Serv_No
         ,BRTH_PLAC = @Brth_Plac
         ,ISSU_PLAC = @Issu_Plac
         ,FATH_WORK = @Fath_Work
         ,HIST_DESC = @Hist_Desc
         ,INTR_FILE_NO = @Intr_File_No
         ,CNTR_CODE = @Cntr_Code
         ,DPST_ACNT_SLRY_BANK = @Dpst_Acnt_Slry_Bank
         ,DPST_ACNT_SLRY = @Dpst_Acnt_Slry
     WHERE Figh_File_No = @File_No
       AND [RQRO_RQST_RQID] = @Rqro_Rqst_Rqid
       AND [RQRO_RWNO] = @Rqro_Rwno;
END
GO
