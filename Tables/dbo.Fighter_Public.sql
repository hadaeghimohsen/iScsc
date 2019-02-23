CREATE TABLE [dbo].[Fighter_Public]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_REGN_PRVN_CNTY_CODE] DEFAULT ('001'),
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_REGN_PRVN_CODE] DEFAULT ('001'),
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_REGN_CODE] DEFAULT ('999'),
[DISE_CODE] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CLUB_CODE] [bigint] NULL,
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [int] NOT NULL CONSTRAINT [DF_FGPB_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FRST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_FRST_NAME] DEFAULT ('FRST_NAME'),
[LAST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_LAST_NAME] DEFAULT ('LAST_NAME'),
[FATH_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_FGPB_FATH_NAME] DEFAULT ('FATH_NAME'),
[SEX_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_FGPB_SEX_TYPE] DEFAULT ('001'),
[NATL_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BRTH_DATE] [datetime] NULL,
[CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COCH_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GUDG_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLOB_CODE] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EDUC_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FGPB_TYPE] DEFAULT ('001'),
[POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INSR_NUMB] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INSR_DATE] [datetime] NULL,
[COCH_FILE_NO] [bigint] NULL,
[COCH_CRTF_DATE] [date] NULL,
[CBMT_CODE] [bigint] NULL,
[DAY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_TIME] [time] NULL,
[CALC_EXPN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTV_TAG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Fighter_Public_ACTV_TAG] DEFAULT ('101'),
[BLOD_GROP] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FNGR_PRNT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [real] NULL,
[CORD_Y] [real] NULL,
[MOST_DEBT_CLNG] [bigint] NULL,
[SERV_NO] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BRTH_PLAC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ISSU_PLAC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FATH_WORK] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HIST_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INTR_FILE_NO] [bigint] NULL,
[CNTR_CODE] [bigint] NULL,
[DPST_ACNT_SLRY_BANK] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DPST_ACNT_SLRY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID] [bigint] NULL,
[MOM_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DAD_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOM_TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DAD_TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOM_CHAT_ID] [bigint] NULL,
[DAD_CHAT_ID] [bigint] NULL,
[IDTY_NUMB] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WATR_FABR_NUMB] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GAS_FABR_NUMB] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POWR_FABR_NUMB] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BULD_AREA] [int] NULL,
[CHLD_FMLY_NUMB] [smallint] NULL,
[DPEN_FMLY_NUMB] [smallint] NULL,
[FMLY_NUMB] [int] NULL,
[HIRE_DATE] [datetime] NULL,
[HIRE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HIRE_PLAC_CODE] [bigint] NULL,
[HOME_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HIRE_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HIRE_TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SALR_PLAC_CODE] [bigint] NULL,
[UNIT_BLOK_CNDO_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_BLOK_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UNIT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PUNT_BLOK_CNDO_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PUNT_BLOK_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PUNT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PHAS_NUMB] [smallint] NULL,
[HIRE_DEGR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HIRE_PLAC_DEGR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCOR_NUMB] [smallint] NULL,
[HOME_REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOME_REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOME_REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOME_POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOME_CORD_X] [float] NULL,
[HOME_CORD_Y] [float] NULL,
[HOME_ZIP_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZIP_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RISK_CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RISK_NUMB] [smallint] NULL,
[WAR_DAY_NUMB] [int] NULL,
[CPTV_DAY_NUMB] [int] NULL,
[MRID_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JOB_TITL_CODE] [bigint] NULL,
[CMNT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PASS_WORD] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$ADEL_FGPB]
   ON  [dbo].[Fighter_Public]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   
   DECLARE C$FGPB CURSOR FOR
      SELECT RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO FROM DELETED D 
       WHERE D.Rect_Code = '004';

   DECLARE @RqroRqstRqid      BIGINT
          ,@RqroRwno          SMALLINT            
          ,@FighFileNo        BIGINT;
   
   OPEN C$FGPB;
   NextFromFGPB:
   FETCH NEXT FROM C$FGPB INTO @RqroRqstRqid, @RqroRwno, @FighFileNo;
   
   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM Fighter_Public I 
           WHERE I.FIGH_FILE_NO = @FighFileNo
             AND I.RWNO = (SELECT MAX(RWNO) FROM FIGHTER_PUBLIC M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET FGPB_RWNO_DNRM = S.RWNO
            ,NAME_DNRM      = S.FRST_NAME + ', ' + S.LAST_NAME
            ,FRST_NAME_DNRM = s.FRST_NAME
            ,LAST_NAME_DNRM = s.LAST_NAME
            ,FATH_NAME_DNRM = S.FATH_NAME
            ,POST_ADRS_DNRM = S.POST_ADRS
            ,SEX_TYPE_DNRM  = S.SEX_TYPE
            ,BRTH_DATE_DNRM = S.BRTH_DATE
            ,CELL_PHON_DNRM = S.CELL_PHON
            ,TELL_PHON_DNRM = S.TELL_PHON
            ,FGPB_TYPE_DNRM = S.[TYPE]
            ,INSR_NUMB_DNRM = S.INSR_NUMB
            ,INSR_DATE_DNRM = S.INSR_DATE
            ,CTGY_CODE_DNRM = S.CTGY_CODE
            ,MTOD_CODE_DNRM = S.MTOD_CODE
            ,CLUB_CODE_DNRM = S.CLUB_CODE
            ,COCH_FILE_NO_DNRM = S.COCH_FILE_NO
            ,CBMT_CODE_DNRM = S.CBMT_CODE
            ,DAY_TYPE_DNRM  = S.DAY_TYPE
            ,ATTN_TIME_DNRM = S.ATTN_TIME
            ,COCH_CRTF_YEAR_DNRM = CASE WHEN S.[TYPE] IN ('003', '004') THEN DATEDIFF(YEAR, COALESCE(S.COCH_CRTF_DATE, GETDATE()), GETDATE()) + 1 ELSE NULL END
            ,ACTV_TAG_DNRM  = S.ACTV_TAG
            ,BLOD_GROP_DNRM = S.BLOD_GROP
            ,FNGR_PRNT_DNRM = S.FNGR_PRNT
            ,SUNT_BUNT_DEPT_ORGN_CODE_DNRM = S.SUNT_BUNT_DEPT_ORGN_CODE
            ,SUNT_BUNT_DEPT_CODE_DNRM = S.SUNT_BUNT_DEPT_CODE
            ,SUNT_BUNT_CODE_DNRM = S.SUNT_BUNT_CODE
            ,SUNT_CODE_DNRM = S.SUNT_CODE
            ,CORD_X_DNRM = S.CORD_X
            ,CORD_Y_DNRM = S.CORD_Y
            ,MOST_DEBT_CLNG_DNRM = S.MOST_DEBT_CLNG
            ,SERV_NO_DNRM = S.SERV_NO
            ,NATL_CODE_DNRM = s.NATL_CODE
            ,GLOB_CODE_DNRM = s.GLOB_CODE
            ,CHAT_ID_DNRM = s.CHAT_ID
            ,FMLY_NUMB_DNRM = s.FMLY_NUMB
            ,MOM_CELL_PHON_DNRM = s.MOM_CELL_PHON
            ,MOM_TELL_PHON_DNRM = s.MOM_TELL_PHON
            ,MOM_CHAT_ID_DNRM = s.MOM_CHAT_ID
            ,DAD_CELL_PHON_DNRM = s.DAD_CELL_PHON
            ,DAD_TELL_PHON_DNRM = S.DAD_TELL_PHON
            ,DAD_CHAT_ID_DNRM = S.DAD_CHAT_ID
            ,DPST_ACNT_SLRY_BANK_DNRM = s.DPST_ACNT_SLRY_BANK
            ,DPST_ACNT_SLRY_DNRM = s.DPST_ACNT_SLRY;;
   
   IF NOT EXISTS(SELECT * FROM Fighter_Public
                  WHERE FIGH_FILE_NO = @FighFileNo
                    AND RECT_CODE = '004'
                )
      UPDATE Fighter
         SET FGPB_RWNO_DNRM = NULL
            ,NAME_DNRM      = NULL
            ,FRST_NAME_DNRM = NULL
            ,LAST_NAME_DNRM = NULL
            ,FATH_NAME_DNRM = NULL
            ,POST_ADRS_DNRM = NULL
            ,SEX_TYPE_DNRM  = NULL
            ,BRTH_DATE_DNRM = NULL
            ,CELL_PHON_DNRM = NULL
            ,TELL_PHON_DNRM = NULL
            ,FGPB_TYPE_DNRM = NULL
            ,INSR_NUMB_DNRM = NULL
            ,INSR_DATE_DNRM = NULL
            ,CTGY_CODE_DNRM = NULL
            ,MTOD_CODE_DNRM = NULL
            ,CLUB_CODE_DNRM = NULL
            ,COCH_FILE_NO_DNRM = NULL
            ,CBMT_CODE_DNRM = NULL
            ,DAY_TYPE_DNRM  = NULL
            ,ATTN_TIME_DNRM = NULL
            ,COCH_CRTF_YEAR_DNRM = NULL
            ,ACTV_TAG_DNRM  = NULL
            ,BLOD_GROP_DNRM = NULL
            ,FNGR_PRNT_DNRM = NULL
            ,SUNT_BUNT_DEPT_ORGN_CODE_DNRM = NULL
            ,SUNT_BUNT_DEPT_CODE_DNRM = NULL
            ,SUNT_BUNT_CODE_DNRM = NULL
            ,SUNT_CODE_DNRM = NULL
            ,CORD_X_DNRM = NULL
            ,CORD_Y_DNRM = NULL
            ,MOST_DEBT_CLNG_DNRM = NULL
            ,SERV_NO_DNRM = NULL
            ,NATL_CODE_DNRM = NULL
            ,GLOB_CODE_DNRM = NULL
            ,CHAT_ID_DNRM = NULL
            ,FMLY_NUMB_DNRM = NULL
            ,MOM_CELL_PHON_DNRM = NULL
            ,MOM_TELL_PHON_DNRM = NULL
            ,MOM_CHAT_ID_DNRM = NULL
            ,DAD_CELL_PHON_DNRM = NULL
            ,DAD_TELL_PHON_DNRM = NULL
            ,DAD_CHAT_ID_DNRM = NULL
            ,DPST_ACNT_SLRY_BANK_DNRM = NULL
            ,DPST_ACNT_SLRY_DNRM = NULL
      WHERE FILE_NO = @FighFileNo;

   CLOSE C$FGPB;
   DEALLOCATE C$FGPB;         
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_FGPB]
   ON  [dbo].[Fighter_Public]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Fighter_Public T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY             = UPPER(SUSER_NAME())
            ,CRET_DATE           = GETDATE()
            ,RWNO                = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Fighter_Public WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE /*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/);
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_FGPB]
   ON  [dbo].[Fighter_Public]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   --BEGIN TRAN TCG$AUPD_FGPB;
   -- Insert statements for trigger here
   
   DECLARE @REGN_PRVN_CNTY_CODE VARCHAR(3)          ,@REGN_PRVN_CODE      VARCHAR(3)
          ,@REGN_CODE           VARCHAR(3)          ,@DISE_CODE           BIGINT
          ,@CTGY_CODE           BIGINT              ,@CLUB_CODE           BIGINT
          ,@MTOD_CODE           BIGINT              ,@RQRO_RQST_RQID      BIGINT
          ,@RQRO_RWNO           SMALLINT            ,@FIGH_FILE_NO        BIGINT
          ,@RWNO                INT                 ,@RECT_CODE           VARCHAR(3)
          ,@FRST_NAME           NVARCHAR(250)       ,@LAST_NAME           NVARCHAR(250)
          ,@FATH_NAME           NVARCHAR(250)       ,@SEX_TYPE            VARCHAR(3)
          ,@NATL_CODE           VARCHAR(10)         ,@BRTH_DATE           DATETIME
          ,@CELL_PHON           VARCHAR(11)         ,@TELL_PHON           VARCHAR(11)
          ,@COCH_DEG            VARCHAR(3)          ,@GUDG_DEG            VARCHAR(3)
          ,@GLOB_CODE           NVARCHAR(20)        ,@TYPE                VARCHAR(3)
          ,@POST_ADRS           NVARCHAR(1000)      ,@EMAL_ADRS           VARCHAR(250)
          ,@INSR_NUMB           VARCHAR(10)         ,@INSR_DATE           DATE
          ,@COCH_FILE_NO        BIGINT              ,@CBMT_CODE           BIGINT
          ,@DAY_TYPE            VARCHAR(3)          ,@ATTN_TIME           TIME(7)
          ,@EDUC_DEG            VARCHAR(3)          ,@COCH_CRTF_DATE      DATE
          ,@CALC_EXPN_TYPE      VARCHAR(3)          ,@ACTV_TAG            VARCHAR(3)
          ,@BLOD_GROP           VARCHAR(3)          ,@FNGR_PRNT           VARCHAR(20)
          ,@SUNT_BUNT_DEPT_ORGN_CODE VARCHAR(2)     ,@SUNT_BUNT_DEPT_CODE VARCHAR(2)
          ,@SUNT_BUNT_CODE      VARCHAR(2)          ,@SUNT_CODE           VARCHAR(4)
          ,@CORD_X              REAL                ,@CORD_Y              REAL
          ,@MOST_DEBT_CLNG      BIGINT              ,@SERV_NO             NVARCHAR(50)
          ,@BRTH_PLAC           NVARCHAR(100)       ,@ISSU_PLAC           NVARCHAR(100)
          ,@FATH_WORK           NVARCHAR(150)       ,@HIST_DESC           NVARCHAR(500)
          ,@INTR_FILE_NO        BIGINT              ,@DPST_ACNT_SLRY_BANK NVARCHAR(50)
          ,@DPST_ACNT_SLRY      VARCHAR(50)         ,@CHAT_ID             BIGINT
          ,@FMLY_NUMB           INT                 ,@MOM_CELL_PHON       VARCHAR(11)
          ,@MOM_TELL_PHON       VARCHAR(11)         ,@MOM_CHAT_ID         BIGINT
          ,@DAD_CELL_PHON       VARCHAR(11)         ,@DAD_TELL_PHON       VARCHAR(11)
          ,@DAD_CHAT_ID         BIGINT;
          
   -- FETCH LAST INFORMATION;
   SELECT TOP 1
          @REGN_PRVN_CNTY_CODE = T.[REGN_PRVN_CNTY_CODE]          , @REGN_PRVN_CODE = T.[REGN_PRVN_CODE]
         ,@REGN_CODE           = T.[REGN_CODE]                    , @DISE_CODE      = T.[DISE_CODE]
         ,@CTGY_CODE           = T.[CTGY_CODE]                    , @CLUB_CODE      = T.[CLUB_CODE]
         ,@MTOD_CODE           = T.[MTOD_CODE]                    , @RQRO_RQST_RQID = T.[RQRO_RQST_RQID]
         ,@RQRO_RWNO           = T.[RQRO_RWNO]                    , @FIGH_FILE_NO   = T.[FIGH_FILE_NO]
         ,@RWNO                = T.[RWNO]                         , @RECT_CODE      = T.[RECT_CODE]
         ,@FRST_NAME           = T.[FRST_NAME]                    , @LAST_NAME      = T.[LAST_NAME]
         ,@FATH_NAME           = T.[FATH_NAME]                    , @SEX_TYPE       = T.[SEX_TYPE]
         ,@NATL_CODE           = T.[NATL_CODE]                    , @BRTH_DATE      = T.[BRTH_DATE]
         ,@CELL_PHON           = T.[CELL_PHON]                    , @TELL_PHON      = T.[TELL_PHON]
         ,@COCH_DEG            = T.[COCH_DEG]                     , @GUDG_DEG       = T.[GUDG_DEG]
         ,@GLOB_CODE           = T.[GLOB_CODE]                    , @TYPE           = T.[TYPE]
         ,@POST_ADRS           = T.[POST_ADRS]                    , @EMAL_ADRS      = T.[EMAL_ADRS]
         ,@INSR_NUMB           = T.INSR_NUMB                      , @INSR_DATE   = T.INSR_DATE
         ,@COCH_FILE_NO        = T.[COCH_FILE_NO]                 , @CBMT_CODE      = T.[CBMT_CODE]
         ,@DAY_TYPE            = T.[DAY_TYPE]                     , @ATTN_TIME      = T.[ATTN_TIME]
         ,@EDUC_DEG            = T.[EDUC_DEG]                     , @COCH_CRTF_DATE = T.[COCH_CRTF_DATE]
         ,@CALC_EXPN_TYPE      = T.CALC_EXPN_TYPE                 , @ACTV_TAG       = T.[ACTV_TAG] 
         ,@BLOD_GROP           = T.BLOD_GROP                      , @FNGR_PRNT      = T.[FNGR_PRNT]
         ,@SUNT_BUNT_DEPT_ORGN_CODE = T.SUNT_BUNT_DEPT_ORGN_CODE  , @SUNT_BUNT_DEPT_CODE = T.SUNT_BUNT_DEPT_CODE
         ,@SUNT_BUNT_CODE      = T.SUNT_BUNT_CODE                 , @SUNT_CODE      = T.SUNT_CODE
         ,@CORD_X              = T.CORD_X                         , @CORD_Y         = T.CORD_Y
         ,@MOST_DEBT_CLNG      = T.MOST_DEBT_CLNG                 , @SERV_NO        = T.SERV_NO
         ,@BRTH_PLAC           = T.BRTH_PLAC                      , @ISSU_PLAC      = T.ISSU_PLAC
         ,@FATH_WORK           = T.FATH_WORK                      , @HIST_DESC      = T.HIST_DESC
         ,@INTR_FILE_NO        = T.INTR_FILE_NO                   , @DPST_ACNT_SLRY_BANK = T.DPST_ACNT_SLRY_BANK
         ,@DPST_ACNT_SLRY      = T.DPST_ACNT_SLRY                 , @CHAT_ID        = T.CHAT_ID
         ,@FMLY_NUMB           = T.FMLY_NUMB                      , @MOM_CELL_PHON  = T.MOM_CELL_PHON
         ,@MOM_TELL_PHON       = T.MOM_TELL_PHON                  , @MOM_CHAT_ID    = T.MOM_CHAT_ID
         ,@DAD_CELL_PHON       = T.DAD_CELL_PHON                  , @DAD_TELL_PHON  = T.DAD_TELL_PHON
         ,@DAD_CHAT_ID         = T.DAD_CHAT_ID
     FROM [dbo].[Fighter_Public] T , INSERTED S
     WHERE T.FIGH_FILE_NO   = S.FIGH_FILE_NO
     ORDER BY T.RQRO_RQST_RQID DESC, T.CRET_DATE DESC;
   
   -- 1396/11/22 * بررسی اینکه ستون هایی که اطلاعات آنها خالی می باشند مقدار "نال" به انها داده شود
   /*IF @FATH_NAME = '' SET @FATH_NAME = NULL;
   IF @POST_ADRS = '' SET @POST_ADRS = NULL;
   IF @CELL_PHON = '' SET @CELL_PHON = NULL;
   IF @TELL_PHON = '' SET @TELL_PHON = NULL;  
   IF @INSR_NUMB = '' SET @INSR_NUMB = NULL;
   IF CAST(@INSR_DATE AS DATE) = '1900-01-01' SET @INSR_DATE = NULL;
   IF @BLOD_GROP = '' SET @BLOD_GROP = NULL;
   IF @FNGR_PRNT = '' SET @FNGR_PRNT = NULL;
   IF @CORD_X = 0 SET @CORD_X = NULL;
   IF @CORD_Y = 0 SET @CORD_Y = NULL;
   IF @SERV_NO = '' SET @SERV_NO = NULL;
   IF @NATL_CODE = '0' OR @NATL_CODE = '' SET @NATL_CODE = NULL;
   IF @GLOB_CODE = '' SET @GLOB_CODE = NULL;*/
   IF @CHAT_ID = 0 SET @CHAT_ID = NULL;
   
   -- 1397/12/4 * 
   DECLARE @DuplNatlCode VARCHAR(3)
          ,@DuplCellPhon VARCHAR(3);
          
   SELECT @DuplNatlCode = s.DUPL_NATL_CODE
         ,@DuplCellPhon = s.DUPL_CELL_PHON
     FROM dbo.Settings s 
    WHERE s.CLUB_CODE = @CLUB_CODE;
   
   IF(ISNULL(@DuplNatlCode, '002') = '001' OR ISNULL(@DuplCellPhon, '002') = '001')
   BEGIN
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter f, Inserted i
          WHERE f.FILE_NO <> i.FIGH_FILE_NO
            AND (f.NATL_CODE_DNRM = @NATL_CODE OR f.CELL_PHON_DNRM = @CELL_PHON)
      )
      BEGIN
         RAISERROR(N'شماره کد ملی یا شماره تلفن تکراری می باشد', 16, 1);
         ROLLBACK --TRAN TCG$AUPD_FGPB;
      END
   END
   
   IF @TYPE IN ( '001', '004', '005', '006' ) AND 
      NOT EXISTS(SELECT * FROM Request WHERE RQID = @RQRO_RQST_RQID AND RQTP_CODE IN ('013', '014', '022', '023', '025')) -- درخواست استخدامی نباشد
   BEGIN
      IF NOT EXISTS (SELECT * FROM Club_Method WHERE CODE = @CBMT_CODE) 
      BEGIN
         RAISERROR(N'برنامه گروه مشخص نشده', 16, 1);
         ROLLBACK --TRAN TCG$AUPD_FGPB;
      END  
      BEGIN    
         SELECT @COCH_FILE_NO = COCH_FILE_NO
               ,@CLUB_CODE    = CLUB_CODE
               ,@MTOD_CODE    = MTOD_CODE
               ,@ATTN_TIME    = STRT_TIME
               ,@DAY_TYPE     = DAY_TYPE
           FROM Club_Method
          WHERE CODE = @CBMT_CODE;
          
          UPDATE dbo.Fighter_Public 
             SET COCH_FILE_NO = @COCH_FILE_NO
                ,CLUB_CODE    = @CLUB_CODE
                ,MTOD_CODE    = @MTOD_CODE
                ,ATTN_TIME    = @ATTN_TIME
                ,DAY_TYPE     = @DAY_TYPE
           WHERE EXISTS(
            SELECT *
              FROM INSERTED S
             WHERE dbo.Fighter_Public.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
                   dbo.Fighter_Public.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
                   dbo.Fighter_Public.RECT_CODE      = S.RECT_CODE
           );
       END
         
     IF NOT EXISTS(SELECT * FROM Fighter_Public WHERE FIGH_FILE_NO = @FIGH_FILE_NO AND RECT_CODE = '004')
            SELECT @CTGY_CODE = CODE
              FROM Category_Belt
             WHERE MTOD_CODE = @MTOD_CODE
               AND ORDR = 0;
         IF @CTGY_CODE IS NULL
         BEGIN
            RAISERROR(N'زیر گروه مشخص نشده', 16, 1);
            ROLLBACK --TRAN TCG$AUPD_FGPB;
         END
   END
   ELSE IF @TYPE IN ('003') AND @RECT_CODE = '004'
   BEGIN
      SELECT @CALC_EXPN_TYPE = '001';
   END
   
   -- ثبت میزان سقف بدهی در تاریخ 1395/05/15
   IF @Rwno = 1 AND @Rect_Code = '001' AND @Most_Debt_Clng = 0
   BEGIN      
      SELECT @MOST_DEBT_CLNG = ISNULL(MOST_DEBT_CLNG_AMNT, 0)
        FROM dbo.Settings
       WHERE CLUB_CODE = @Club_Code
         AND DEBT_CLNG_STAT = '002';
      
      SET @Most_Debt_Clng = ISNULL(@Most_Debt_Clng, 0);
   END
   
   -- 1396/11/22 * بررسی تعداد کد خانوار مشترکین
   --IF @GLOB_CODE IS NOT NULL AND @GLOB_CODE != ''
   --BEGIN      
   --   SELECT @FMLY_NUMB = COUNT(*) 
   --     FROM dbo.Fighter_Public fp
   --    WHERE fp.RECT_CODE = '004'
   --      AND fp.GLOB_CODE = @GLOB_CODE
   --      AND fp.ACTV_TAG >= '101';
   --END
   --ELSE
   --   SET @FMLY_NUMB = NULL;
   
   MERGE dbo.Fighter_Public T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY             = UPPER(SUSER_NAME())
            ,MDFY_DATE           = GETDATE()
            ,REGN_PRVN_CNTY_CODE = CASE S.REGN_PRVN_CNTY_CODE WHEN NULL THEN @REGN_PRVN_CNTY_CODE ELSE S.REGN_PRVN_CNTY_CODE END
            ,REGN_PRVN_CODE      = CASE S.REGN_PRVN_CODE      WHEN NULL THEN @REGN_PRVN_CODE      ELSE S.REGN_PRVN_CODE      END
            ,REGN_CODE           = CASE S.REGN_CODE           WHEN NULL THEN @REGN_CODE           ELSE S.REGN_CODE           END
            ,DISE_CODE           = CASE S.DISE_CODE           WHEN NULL THEN @DISE_CODE           ELSE S.DISE_CODE           END
            ,CTGY_CODE           = CASE S.CTGY_CODE           WHEN NULL THEN @CTGY_CODE           ELSE S.CTGY_CODE           END
            ,CLUB_CODE           = CASE S.CLUB_CODE           WHEN NULL THEN @CLUB_CODE           ELSE S.CLUB_CODE           END
            ,MTOD_CODE           = CASE S.MTOD_CODE           WHEN NULL THEN @MTOD_CODE           ELSE S.MTOD_CODE           END
            ,FRST_NAME           = CASE S.FRST_NAME           WHEN NULL THEN @FRST_NAME           ELSE S.FRST_NAME           END
            ,LAST_NAME           = CASE S.LAST_NAME           WHEN NULL THEN @LAST_NAME           ELSE S.LAST_NAME           END
            ,FATH_NAME           = CASE S.FATH_NAME           WHEN NULL THEN @FATH_NAME           ELSE S.FATH_NAME           END
            ,SEX_TYPE            = CASE S.SEX_TYPE            WHEN NULL THEN @SEX_TYPE            ELSE S.SEX_TYPE           END
            ,NATL_CODE           = CASE S.NATL_CODE           WHEN NULL THEN @NATL_CODE           ELSE S.NATL_CODE           END
            ,BRTH_DATE           = CASE S.BRTH_DATE           WHEN NULL THEN @BRTH_DATE           ELSE S.BRTH_DATE           END
            ,CELL_PHON           = CASE S.CELL_PHON           WHEN NULL THEN @CELL_PHON           ELSE S.CELL_PHON           END
            ,TELL_PHON           = CASE S.TELL_PHON           WHEN NULL THEN @TELL_PHON           ELSE S.TELL_PHON           END
            ,COCH_DEG            = CASE S.COCH_DEG            WHEN NULL THEN @COCH_DEG            ELSE S.COCH_DEG       END
            ,GUDG_DEG            = CASE S.GUDG_DEG            WHEN NULL THEN @GUDG_DEG            ELSE S.GUDG_DEG            END
            ,GLOB_CODE           = CASE S.GLOB_CODE           WHEN NULL THEN @GLOB_CODE           ELSE S.GLOB_CODE           END
            ,[TYPE]              = CASE S.[TYPE]              WHEN NULL THEN @TYPE                ELSE S.[TYPE]              END
            ,POST_ADRS           = CASE S.POST_ADRS           WHEN NULL THEN @POST_ADRS           ELSE S.POST_ADRS           END
            ,EMAL_ADRS           = CASE S.EMAL_ADRS           WHEN NULL THEN @EMAL_ADRS           ELSE S.EMAL_ADRS           END
            ,INSR_NUMB           = CASE S.INSR_NUMB           WHEN NULL THEN @INSR_NUMB           ELSE S.INSR_NUMB           END
            ,INSR_DATE           = CASE S.INSR_DATE           WHEN NULL THEN @INSR_DATE           ELSE S.INSR_DATE           END
            ,COCH_FILE_NO        = CASE S.COCH_FILE_NO        WHEN NULL THEN @COCH_FILE_NO        ELSE S.COCH_FILE_NO        END
            --,CBMT_CODE           = CASE S.CBMT_CODE           WHEN NULL THEN @CBMT_CODE           ELSE S.CBMT_CODE           END
            --,DAY_TYPE            = CASE S.DAY_TYPE            WHEN NULL THEN @DAY_TYPE            ELSE S.DAY_TYPE            END
            --,ATTN_TIME           = CASE S.ATTN_TIME           WHEN NULL THEN @ATTN_TIME           ELSE S.ATTN_TIME           END
            ,EDUC_DEG            = CASE S.EDUC_DEG            WHEN NULL THEN @EDUC_DEG            ELSE S.EDUC_DEG            END
            ,COCH_CRTF_DATE      = CASE S.COCH_CRTF_DATE      WHEN NULL THEN @COCH_CRTF_DATE      ELSE S.COCH_CRTF_DATE      END
            ,CALC_EXPN_TYPE      = CASE S.CALC_EXPN_TYPE      WHEN NULL THEN @CALC_EXPN_TYPE      ELSE S.CALC_EXPN_TYPE      END
            ,ACTV_TAG            = CASE S.ACTV_TAG            WHEN NULL THEN @ACTV_TAG            ELSE S.ACTV_TAG            END
            ,BLOD_GROP           = CASE S.BLOD_GROP           WHEN NULL THEN @BLOD_GROP           ELSE S.BLOD_GROP           END
            ,FNGR_PRNT           = CASE S.FNGR_PRNT           WHEN NULL THEN @FNGR_PRNT           ELSE S.FNGR_PRNT           END
            ,SUNT_BUNT_DEPT_ORGN_CODE = CASE S.SUNT_BUNT_DEPT_ORGN_CODE WHEN NULL THEN @SUNT_BUNT_DEPT_ORGN_CODE ELSE S.SUNT_BUNT_DEPT_ORGN_CODE END
            ,SUNT_BUNT_DEPT_CODE = CASE S.SUNT_BUNT_DEPT_CODE WHEN NULL THEN @SUNT_BUNT_DEPT_CODE ELSE S.SUNT_BUNT_DEPT_CODE END
            ,SUNT_BUNT_CODE      = CASE S.SUNT_BUNT_CODE      WHEN NULL THEN @SUNT_BUNT_CODE      ELSE S.SUNT_BUNT_CODE      END
            ,SUNT_CODE           = CASE S.SUNT_CODE           WHEN NULL THEN @SUNT_CODE           ELSE S.SUNT_CODE           END
            ,CORD_X              = CASE S.CORD_X              WHEN NULL THEN @CORD_X              ELSE S.CORD_X              END
            ,CORD_Y              = CASE S.CORD_Y              WHEN NULL THEN @CORD_Y              ELSE S.CORD_Y              END
            ,MOST_DEBT_CLNG      = CASE S.MOST_DEBT_CLNG      WHEN 0    THEN @MOST_DEBT_CLNG      ELSE S.MOST_DEBT_CLNG      END
            ,SERV_NO             = CASE S.SERV_NO             WHEN NULL THEN @SERV_NO             ELSE S.SERV_NO             END
            ,Brth_Plac           = CASE S.BRTH_PLAC           WHEN NULL THEN @BRTH_PLAC           ELSE S.BRTH_PLAC           END
            ,ISSU_PLAC           = CASE S.ISSU_PLAC           WHEN NULL THEN @ISSU_PLAC           ELSE S.ISSU_PLAC           END
            ,FATH_WORK           = CASE S.FATH_WORK           WHEN NULL THEN @FATH_WORK           ELSE S.FATH_WORK           END
            ,HIST_DESC           = CASE S.HIST_DESC           WHEN NULL THEN @HIST_DESC           ELSE S.HIST_DESC           END
            ,INTR_FILE_NO        = CASE S.INTR_FILE_NO        WHEN NULL THEN @INTR_FILE_NO        ELSE S.INTR_FILE_NO        END
            ,DPST_ACNT_SLRY_BANK = CASE S.DPST_ACNT_SLRY_BANK WHEN NULL THEN @DPST_ACNT_SLRY_BANK ELSE S.DPST_ACNT_SLRY_BANK END
            ,DPST_ACNT_SLRY      = CASE S.DPST_ACNT_SLRY      WHEN NULL THEN @DPST_ACNT_SLRY      ELSE S.DPST_ACNT_SLRY      END
            ,CHAT_ID             = CASE S.CHAT_ID             WHEN NULL THEN @CHAT_ID             ELSE S.CHAT_ID             END
            ,FMLY_NUMB           = CASE S.FMLY_NUMB           WHEN NULL THEN @FMLY_NUMB           ELSE S.FMLY_NUMB           END
            ,MOM_CELL_PHON       = CASE S.MOM_CELL_PHON       WHEN NULL THEN @MOM_CELL_PHON       ELSE S.MOM_CELL_PHON       END
            ,MOM_TELL_PHON       = CASE S.MOM_TELL_PHON       WHEN NULL THEN @MOM_TELL_PHON       ELSE S.MOM_TELL_PHON       END
            ,MOM_CHAT_ID         = CASE S.MOM_CHAT_ID         WHEN NULL THEN @MOM_CHAT_ID         ELSE S.MOM_CHAT_ID         END
            ,DAD_CELL_PHON       = CASE S.DAD_CELL_PHON       WHEN NULL THEN @DAD_CELL_PHON       ELSE S.DAD_CELL_PHON       END
            ,DAD_TELL_PHON       = CASE S.DAD_TELL_PHON       WHEN NULL THEN @DAD_TELL_PHON       ELSE S.DAD_TELL_PHON       END
            ,DAD_CHAT_ID         = CASE S.DAD_CHAT_ID         WHEN NULL THEN @DAD_CHAT_ID         ELSE S.DAD_CHAT_ID         END;
            
            
   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
       WHERE I.RWNO = (SELECT MAX(RWNO) FROM FIGHTER_PUBLIC M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET FGPB_RWNO_DNRM = S.RWNO
            ,NAME_DNRM      = S.LAST_NAME + ', ' + S.FRST_NAME
            ,FRST_NAME_DNRM = s.FRST_NAME
            ,LAST_NAME_DNRM = S.LAST_NAME
            ,FATH_NAME_DNRM = S.FATH_NAME
            ,POST_ADRS_DNRM = S.POST_ADRS
            ,SEX_TYPE_DNRM  = S.SEX_TYPE
            ,BRTH_DATE_DNRM = S.BRTH_DATE
            ,CELL_PHON_DNRM = S.CELL_PHON
            ,TELL_PHON_DNRM = S.TELL_PHON
            ,FGPB_TYPE_DNRM = S.[TYPE]
            ,INSR_NUMB_DNRM = S.INSR_NUMB
            ,INSR_DATE_DNRM = S.INSR_DATE
            ,CTGY_CODE_DNRM = S.CTGY_CODE
            ,MTOD_CODE_DNRM = S.MTOD_CODE
            ,CLUB_CODE_DNRM = S.CLUB_CODE
            ,COCH_FILE_NO_DNRM = S.COCH_FILE_NO
            ,CBMT_CODE_DNRM = S.CBMT_CODE
            ,DAY_TYPE_DNRM  = S.DAY_TYPE
            ,ATTN_TIME_DNRM = S.ATTN_TIME
            ,COCH_CRTF_YEAR_DNRM = CASE WHEN S.[TYPE] IN ('003', '004') THEN DATEDIFF(YEAR, COALESCE(S.COCH_CRTF_DATE, GETDATE()), GETDATE()) + 1 ELSE NULL END
            ,ACTV_TAG_DNRM  = S.ACTV_TAG
            ,BLOD_GROP_DNRM = S.BLOD_GROP
            ,FNGR_PRNT_DNRM = S.FNGR_PRNT
            ,SUNT_BUNT_DEPT_ORGN_CODE_DNRM = S.SUNT_BUNT_DEPT_ORGN_CODE
            ,SUNT_BUNT_DEPT_CODE_DNRM = S.SUNT_BUNT_DEPT_CODE
            ,SUNT_BUNT_CODE_DNRM = S.SUNT_BUNT_CODE
            ,SUNT_CODE_DNRM = S.SUNT_CODE
            ,CORD_X_DNRM = S.CORD_X
            ,CORD_Y_DNRM = S.CORD_Y
            ,MOST_DEBT_CLNG_DNRM = S.MOST_DEBT_CLNG
            ,SERV_NO_DNRM = S.SERV_NO
            ,NATL_CODE_DNRM = s.NATL_CODE
            ,GLOB_CODE_DNRM = S.GLOB_CODE
            ,CHAT_ID_DNRM = S.CHAT_ID
            ,MOM_CELL_PHON_DNRM = s.MOM_CELL_PHON
            ,MOM_TELL_PHON_DNRM = s.MOM_TELL_PHON
            ,MOM_CHAT_ID_DNRM = s.MOM_CHAT_ID
            ,DAD_CELL_PHON_DNRM = s.DAD_CELL_PHON
            ,DAD_TELL_PHON_DNRM = S.DAD_TELL_PHON
            ,DAD_CHAT_ID_DNRM = S.DAD_CHAT_ID
            ,DPST_ACNT_SLRY_BANK_DNRM = s.DPST_ACNT_SLRY_BANK
            ,DPST_ACNT_SLRY_DNRM = s.DPST_ACNT_SLRY;
END
;
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [CK_FGPB_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FGPB_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_CNTR] FOREIGN KEY ([CNTR_CODE]) REFERENCES [dbo].[Request] ([RQID])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_DSTP] FOREIGN KEY ([DISE_CODE]) REFERENCES [dbo].[Diseases_Type] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_HPLC] FOREIGN KEY ([HIRE_PLAC_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_INTF] FOREIGN KEY ([INTR_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_JOBT] FOREIGN KEY ([JOB_TITL_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_PBLK] FOREIGN KEY ([PUNT_BLOK_CNDO_CODE], [PUNT_BLOK_CODE]) REFERENCES [dbo].[Cando_Block] ([CNDO_CODE], [CODE])
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_SPLC] FOREIGN KEY ([SALR_PLAC_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Public] WITH NOCHECK ADD CONSTRAINT [FK_FGPB_SUNT] FOREIGN KEY ([SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]) REFERENCES [dbo].[Sub_Unit] ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Public] ADD CONSTRAINT [FK_FGPB_UNIT] FOREIGN KEY ([UNIT_BLOK_CNDO_CODE], [UNIT_BLOK_CODE], [UNIT_CODE]) REFERENCES [dbo].[Cando_Block_Unit] ([BLOK_CNDO_CODE], [BLOK_CODE], [CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'محل تولد', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'BRTH_PLAC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'متراژ', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'BULD_AREA'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد چت تلگرام', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'CHAT_ID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد فرزندان', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'CHLD_FMLY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'CMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره قرارداد پرسنل', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'CNTR_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت روز اسارت', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'CPTV_DAY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد اعضای تحت تکفل', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'DPEN_FMLY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره حساب واریز حقوق و دستمزد', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'DPST_ACNT_SLRY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بانک حساب واریز حقوق و دستمزد', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'DPST_ACNT_SLRY_BANK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شغل پدر', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'FATH_WORK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد خانوار', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'FMLY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره فابریک کنتور گاز', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'GAS_FABR_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'همراه محل کار', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_CELL_PHON'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ عضویت * استخدام', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درجه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_DEGR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محل خدمت', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_PLAC_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درجه جایگاه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_PLAC_DEGR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تلفن محل کار', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_TELL_PHON'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع عضویت * استخدام', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIRE_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سابقه ورزشی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HIST_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس سکونت فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_POST_ADRS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ناحیه سکونت فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_REGN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کشور سکونت فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_REGN_PRVN_CNTY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'استان سکونت فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_REGN_PRVN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت سکونت', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد پستی سکونت فعلی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'HOME_ZIP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره شناسنامه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'IDTY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'معرف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'INTR_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محل صدور', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'ISSU_PLAC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رمز اینترنتی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'PASS_WORD'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره فاز پروژه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'PHAS_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره فابریک کنتور برق', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'POWR_FABR_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پروژه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'PUNT_BLOK_CNDO_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بلوک پروژه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'PUNT_BLOK_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد پروژه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'PUNT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد جانبازی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'RISK_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد جانبازی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'RISK_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محل لیست کسر حقوق', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'SALR_PLAC_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان امتیاز', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'SCOR_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد سازمانی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'SERV_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مجتمع', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'UNIT_BLOK_CNDO_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بلوک', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'UNIT_BLOK_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'UNIT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت روز حضور در جنگ', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'WAR_DAY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره فابریک کنتور آب', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'WATR_FABR_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد پستی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Public', 'COLUMN', N'ZIP_CODE'
GO
