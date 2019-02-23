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
	@Glob_Code NVARCHAR(50),
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
	@Dpst_Acnt_Slry VARCHAR(50),
	@Chat_Id BIGINT,
	@Mom_Cell_Phon VARCHAR(11),
	@Mom_Tell_Phon VARCHAR(11),
	@Mom_Chat_Id BIGINT,
	@Dad_Cell_Phon VARCHAR(11),
	@Dad_Tell_Phon VARCHAR(11),
	@Dad_Chat_Id BIGINT,
	@Idty_Numb VARCHAR(20),
	@Watr_Fabr_Numb NVARCHAR(30),
	@Gas_Fabr_Numb NVARCHAR(30),
	@Powr_Fabr_Numb NVARCHAR(30),
	@Buld_Area INT,
	@Chld_Fmly_Numb SMALLINT,
	@Dpen_Fmly_Numb SMALLINT,
	@Fmly_Numb SMALLINT,
	@Hire_Date DATETIME,
	@Hire_Type VARCHAR(3),
	@Hire_Plac_Code BIGINT,
	@Home_Type VARCHAR(3),
	@Hire_Cell_Phon VARCHAR(11),
	@Hire_Tell_Phon VARCHAR(11),
	@Salr_Plac_Code BIGINT,
	@Unit_Blok_Cndo_Code VARCHAR(3),
	@Unit_Blok_Code VARCHAR(3),
	@Unit_Code VARCHAR(3),
	@Punt_Blok_Cndo_Code VARCHAR(3),
	@Punt_Blok_Code VARCHAR(3),
	@Punt_Code VARCHAR(3),
	@Phas_Numb SMALLINT,
	@Hire_Degr VARCHAR(3),
	@Hire_Plac_Degr VARCHAR(3),
	@Scor_Numb SMALLINT,
	@Home_Regn_Prvn_Cnty_Code VARCHAR(3),
	@Home_Regn_Prvn_Code VARCHAR(3),
	@Home_Regn_Code VARCHAR(3),
	@Home_Post_Adrs NVARCHAR(1000),
	@Home_Cord_X FLOAT,
	@Home_Cord_Y FLOAT,
	@Home_Zip_Code VARCHAR(10),
	@Zip_Code VARCHAR(10),
	@Risk_Code VARCHAR(20),
	@Risk_Numb SMALLINT,
	@War_Day_Numb SMALLINT,
	@Cptv_Day_Numb SMALLINT,
	@Mrid_Type VARCHAR(3),
	@Job_Titl_Code BIGINT,
	@Cmnt NVARCHAR(4000),
	@Pass_Word VARCHAR(250)
AS
BEGIN
   IF @Intr_File_No = 0 SET @Intr_File_No = NULL
   IF @Cntr_Code = 0 SET @Cntr_Code = NULL;
   IF @Cbmt_Code = 0 SET @Cbmt_Code = NULL;   
   IF @Serv_No = '' SET @Serv_No = NULL;
   IF @Glob_Code = '' OR @Glob_Code = '0' SET @Glob_Code = NULL;
   IF @Fath_Name = '' SET @Fath_Name = NULL;
   IF @Natl_Code = '' SET @Natl_Code = NULL;
   IF @Brth_Date = '1900-01-01' SET @Brth_Date = NULL;
   IF @Cell_Phon = '' SET @Cell_Phon = NULL;
   IF @Tell_Phon = '' SET @Tell_Phon = NULL;
   IF @Post_Adrs = '' SET @Post_Adrs = NULL;
   IF @Emal_Adrs = '' SET @Emal_Adrs = NULL;
   IF @Insr_Numb = '' SET @Insr_Numb = NULL;
   IF @Insr_Date = '1900-01-01' SET @Insr_Date = NULL;
   IF @CORD_X = 0 SET @CORD_X = NULL;
   IF @CORD_Y = 0 SET @CORD_Y = NULL;
   IF @Chat_Id = 0 SET @Chat_Id = NULL;   
   IF @Blod_Grop = '' SET @Blod_Grop = NULL;
   IF @Mom_Cell_Phon = '' SET @Mom_Cell_Phon = NULL
   IF @Mom_Tell_Phon = '' SET @Mom_Tell_Phon = NULL
   IF @Mom_Chat_Id = '' SET @Mom_Chat_Id = NULL
   IF @Dad_Cell_Phon = '' SET @Dad_Cell_Phon = NULL
   IF @Dad_Tell_Phon = '' SET @Dad_Tell_Phon = NULL
   IF @Dad_Chat_Id = '' SET @Mom_Chat_Id = NULL
   IF @Idty_Numb = '' SET @Idty_Numb = NULL
   IF @Watr_Fabr_Numb = '' SET @Watr_Fabr_Numb = NULL
   IF @Gas_Fabr_Numb = '' SET @Gas_Fabr_Numb = NULL
   IF @Powr_Fabr_Numb = '' SET @Powr_Fabr_Numb = NULL
   IF @Hire_Date = '1900-01-01' SET @Hire_Date = NULL
   IF @Hire_Type = '' SET @Hire_Type = NULL
   IF @Hire_Plac_Code = 0 SET @Hire_Plac_Code = NULL
   IF @Salr_Plac_Code = 0 SET @Salr_Plac_Code = NULL
   IF @Hire_Cell_Phon = '' SET @Hire_Cell_Phon = NULL
   IF @Hire_Tell_Phon = '' SET @Hire_Tell_Phon = NULL
   IF @Unit_Blok_Cndo_Code = '' SET @Unit_Blok_Cndo_Code = NULL
   IF @Unit_Blok_Code = '' SET @Unit_Blok_Code = NULL
   IF @Unit_Code = '' SET @Unit_Code = NULL
   IF @Punt_Blok_Cndo_Code = '' SET @Punt_Blok_Cndo_Code = NULL
   IF @Punt_Blok_Code = '' SET @Punt_Blok_Code = NULL
   IF @Punt_Code = '' SET @Punt_Code = NULL
   IF @Home_Regn_Prvn_Cnty_Code = '' SET @Home_Regn_Prvn_Cnty_Code = NULL
   IF @Home_Regn_Prvn_Code = '' SET @Home_Regn_Prvn_Code = NULL
   IF @Home_Regn_Code = '' SET @Home_Regn_Code = NULL
   IF @Home_Post_Adrs = '' SET @Home_Post_Adrs = NULL
   IF @Home_Zip_Code = '' SET @Home_Zip_Code = NULL
   IF @Zip_Code = '' SET @Zip_Code = NULL
   IF @Risk_Code = '' SET @Risk_Code = NULL
   IF @Job_Titl_Code = 0 SET @Job_Titl_Code = NULL
   IF @Pass_Word = '' SET @Pass_Word = NULL
   IF @Sex_Type = '003' SET @Sex_Type = '001'
   
	INSERT INTO [dbo].[Fighter_Public]
           ([REGN_PRVN_CODE], [REGN_CODE], [DISE_CODE], [MTOD_CODE], [CTGY_CODE]
           ,[CLUB_CODE], [RQRO_RQST_RQID], [RQRO_RWNO], [FIGH_FILE_NO], [RWNO], [RECT_CODE]
           ,[FRST_NAME], [LAST_NAME], [FATH_NAME], [SEX_TYPE], [NATL_CODE], [BRTH_DATE]
           ,[CELL_PHON], [TELL_PHON], [COCH_DEG], [GUDG_DEG], [GLOB_CODE], [TYPE]
           ,[POST_ADRS], [EMAL_ADRS], [INSR_NUMB], [INSR_DATE], [EDUC_DEG], [COCH_FILE_NO]
           ,[CBMT_CODE], [DAY_TYPE], [ATTN_TIME], [COCH_CRTF_DATE], [CALC_EXPN_TYPE],[ACTV_TAG], [BLOD_GROP]
           ,[FNGR_PRNT], [SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]
           ,[CORD_X], [CORD_Y], [MOST_DEBT_CLNG], [SERV_NO], BRTH_PLAC, ISSU_PLAC, FATH_WORK, HIST_DESC, INTR_FILE_NO
           ,[CNTR_CODE], [DPST_ACNT_SLRY_BANK], [DPST_ACNT_SLRY], [CHAT_ID], [MOM_CELL_PHON], [MOM_TELL_PHON], [MOM_CHAT_ID]
           ,[DAD_CELL_PHON], [DAD_TELL_PHON], [DAD_CHAT_ID], IDTY_NUMB, WATR_FABR_NUMB, GAS_FABR_NUMB, POWR_FABR_NUMB, BULD_AREA
           ,CHLD_FMLY_NUMB, DPEN_FMLY_NUMB, FMLY_NUMB, HIRE_DATE, HIRE_TYPE, HIRE_PLAC_CODE, HOME_TYPE, HIRE_CELL_PHON, HIRE_TELL_PHON
           ,SALR_PLAC_CODE, UNIT_BLOK_CNDO_CODE, UNIT_BLOK_CODE, UNIT_CODE, PUNT_BLOK_CNDO_CODE, PUNT_BLOK_CODE, PUNT_CODE, PHAS_NUMB
           ,HIRE_DEGR, HIRE_PLAC_DEGR, SCOR_NUMB, HOME_REGN_PRVN_CNTY_CODE, HOME_REGN_PRVN_CODE, HOME_REGN_CODE, HOME_POST_ADRS
           ,HOME_CORD_X, HOME_CORD_Y, HOME_ZIP_CODE, ZIP_CODE, RISK_CODE, RISK_NUMB, WAR_DAY_NUMB, CPTV_DAY_NUMB, MRID_TYPE, JOB_TITL_CODE, CMNT
           ,PASS_WORD)
     VALUES
           (@Prvn_Code, @Regn_Code, @Dise_Code, @Mtod_Code, @Ctgy_Code 
           ,@Club_Code, @Rqro_Rqst_Rqid, @Rqro_Rwno, @File_No, 0, @Rect_Code
           ,@Frst_Name, @Last_Name, @Fath_Name, @Sex_Type, @Natl_Code, @Brth_Date
           ,@Cell_Phon, @Tell_Phon, @Coch_Deg, @Gudg_Deg, @Glob_Code, @Type
           ,@Post_Adrs, @Emal_Adrs, @Insr_Numb, @Insr_Date, @Educ_Deg, @Coch_File_No 
           ,@Cbmt_Code, @Day_Type, @Attn_Time, @Coch_Crtf_Date, @Calc_Expn_Type, @Actv_Tag, @Blod_Grop
           ,@Fngr_Prnt, @SUNT_BUNT_DEPT_ORGN_CODE, @SUNT_BUNT_DEPT_CODE, @SUNT_BUNT_CODE, @SUNT_CODE
           ,@CORD_X, @CORD_Y, @Most_Debt_Clng, @Serv_No, @BRTH_PLAC, @ISSU_PLAC, @FATH_WORK, @HIST_DESC, @INTR_FILE_NO
           ,@Cntr_Code, @Dpst_Acnt_Slry_Bank, @Dpst_Acnt_Slry, @Chat_Id, @Mom_Cell_Phon, @Mom_Tell_Phon, @Mom_Chat_Id
           ,@Dad_Cell_Phon, @Dad_Tell_Phon, @Dad_Chat_Id, @IDTY_NUMB, @WATR_FABR_NUMB, @GAS_FABR_NUMB, @POWR_FABR_NUMB, @BULD_AREA
           ,@CHLD_FMLY_NUMB, @DPEN_FMLY_NUMB, @FMLY_NUMB, @HIRE_DATE, @HIRE_TYPE, @HIRE_PLAC_CODE, @HOME_TYPE, @HIRE_CELL_PHON, @HIRE_TELL_PHON
           ,@SALR_PLAC_CODE, @UNIT_BLOK_CNDO_CODE, @UNIT_BLOK_CODE, @UNIT_CODE, @PUNT_BLOK_CNDO_CODE, @PUNT_BLOK_CODE, @PUNT_CODE, @PHAS_NUMB
           ,@HIRE_DEGR, @HIRE_PLAC_DEGR, @SCOR_NUMB, @HOME_REGN_PRVN_CNTY_CODE, @HOME_REGN_PRVN_CODE, @HOME_REGN_CODE, @HOME_POST_ADRS
           ,@HOME_CORD_X, @HOME_CORD_Y, @HOME_ZIP_CODE, @ZIP_CODE, @RISK_CODE, @RISK_NUMB, @WAR_DAY_NUMB, @CPTV_DAY_NUMB, @MRID_TYPE, @JOB_TITL_CODE, @CMNT
           ,@Pass_Word
           );
END
GO
