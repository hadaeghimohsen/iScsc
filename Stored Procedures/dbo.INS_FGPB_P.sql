SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_FGPB_P]
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
	@Actv_Tag  VARCHAR(3) = '101',
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
   IF @Cbmt_Code = 0 SET @Cbmt_Code = NULL;   
   
	INSERT INTO [dbo].[Fighter_Public]
           ([REGN_PRVN_CODE], [REGN_CODE], [DISE_CODE], [MTOD_CODE], [CTGY_CODE]
           ,[CLUB_CODE], [RQRO_RQST_RQID], [RQRO_RWNO], [FIGH_FILE_NO], [RWNO], [RECT_CODE]
           ,[FRST_NAME], [LAST_NAME], [FATH_NAME], [SEX_TYPE], [NATL_CODE], [BRTH_DATE]
           ,[CELL_PHON], [TELL_PHON], [COCH_DEG], [GUDG_DEG], [GLOB_CODE], [TYPE]
           ,[POST_ADRS], [EMAL_ADRS], [INSR_NUMB], [INSR_DATE], [EDUC_DEG], [COCH_FILE_NO]
           ,[CBMT_CODE], [DAY_TYPE], [ATTN_TIME], [COCH_CRTF_DATE], [CALC_EXPN_TYPE],[ACTV_TAG], [BLOD_GROP]
           ,[FNGR_PRNT], [SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]
           ,[CORD_X], [CORD_Y], [MOST_DEBT_CLNG], [SERV_NO], BRTH_PLAC, ISSU_PLAC, FATH_WORK, HIST_DESC, INTR_FILE_NO
           ,[CNTR_CODE], [DPST_ACNT_SLRY_BANK], [DPST_ACNT_SLRY])
     VALUES
           (@Prvn_Code, @Regn_Code, @Dise_Code, @Mtod_Code, @Ctgy_Code 
           ,@Club_Code, @Rqro_Rqst_Rqid, @Rqro_Rwno, @File_No, 0, @Rect_Code
           ,@Frst_Name, @Last_Name, @Fath_Name, @Sex_Type, @Natl_Code, @Brth_Date
           ,@Cell_Phon, @Tell_Phon, @Coch_Deg, @Gudg_Deg, @Glob_Code, @Type
           ,@Post_Adrs, @Emal_Adrs, @Insr_Numb, @Insr_Date, @Educ_Deg, @Coch_File_No 
           ,@Cbmt_Code, @Day_Type, @Attn_Time, @Coch_Crtf_Date, @Calc_Expn_Type, @Actv_Tag, @Blod_Grop
           ,@Fngr_Prnt, @SUNT_BUNT_DEPT_ORGN_CODE, @SUNT_BUNT_DEPT_CODE, @SUNT_BUNT_CODE, @SUNT_CODE
           ,@CORD_X, @CORD_Y, @Most_Debt_Clng, @Serv_No, @BRTH_PLAC, @ISSU_PLAC, @FATH_WORK, @HIST_DESC, @INTR_FILE_NO
           ,@Cntr_Code, @Dpst_Acnt_Slry_Bank, @Dpst_Acnt_Slry);
END
GO
