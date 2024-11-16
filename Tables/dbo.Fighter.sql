CREATE TABLE [dbo].[Fighter]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FIGH_REGN_PRVN_CNTY_CODE] DEFAULT ('001'),
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FIGH_REGN_PRVN_CODE] DEFAULT ('001'),
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FILE_NO] [bigint] NOT NULL CONSTRAINT [DF_FIGH_FILE_NO] DEFAULT ((0)),
[TARF_CODE_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOST_DEBT_CLNG_DNRM] [bigint] NULL,
[DEBT_DNRM] [bigint] NULL,
[BUFE_DEBT_DNTM] [bigint] NULL,
[DPST_AMNT_DNRM] [bigint] NULL,
[FGPB_RWNO_DNRM] [int] NULL,
[MBSP_RWNO_DNRM] [smallint] NULL,
[MBCO_RWNO_DNRM] [smallint] NULL,
[MBFZ_RWNO_DNRM] [smallint] NULL,
[MBSM_RWNO_DNRM] [smallint] NULL,
[CAMP_RWNO_DNRM] [smallint] NULL,
[TEST_RWNO_DNRM] [smallint] NULL,
[CLCL_RWNO_DNRM] [smallint] NULL,
[HERT_RWNO_DNRM] [smallint] NULL,
[PSFN_RWNO_DNRM] [smallint] NULL,
[EXAM_RWNO_DNRM] [smallint] NULL,
[BDFT_RWNO_DNRM] [smallint] NULL,
[MBSP_STRT_DATE] [date] NULL,
[MBSP_END_DATE] [date] NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FIGH_CONF_STAT] DEFAULT ('001'),
[CONF_DATE] [datetime] NULL,
[FIGH_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FIGH_FIGH_STAT] DEFAULT ('002'),
[RQST_RQID] [bigint] NULL,
[NAME_DNRM] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FRST_NAME_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_NAME_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FATH_NAME_DNRM] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POST_ADRS_DNRM] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEX_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BRTH_DATE_DNRM] [datetime] NULL,
[CELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INSR_NUMB_DNRM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INSR_DATE_DNRM] [datetime] NULL,
[TEST_DATE_DNRM] [datetime] NULL,
[CAMP_DATE_DNRM] [datetime] NULL,
[CTGY_CODE_DNRM] [bigint] NULL,
[MTOD_CODE_DNRM] [bigint] NULL,
[CLUB_CODE_DNRM] [bigint] NULL,
[COCH_FILE_NO_DNRM] [bigint] NULL,
[COCH_CRTF_YEAR_DNRM] [smallint] NULL,
[CBMT_CODE_DNRM] [bigint] NULL,
[DAY_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_TIME_DNRM] [time] NULL,
[ACTV_TAG_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BLOD_GROP_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMAG_RCDC_RCID_DNRM] [bigint] NULL,
[IMAG_RWNO_DNRM] [smallint] NULL,
[CARD_NUMB_DNRM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_ORGN_CODE_DNRM] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_CODE_DNRM] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_CODE_DNRM] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_CODE_DNRM] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORGN_CODE_DNRM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X_DNRM] [real] NULL,
[CORD_Y_DNRM] [real] NULL,
[SERV_NO_DNRM] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NATL_CODE_DNRM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLOB_CODE_DNRM] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHAT_ID_DNRM] [bigint] NULL,
[MOM_CELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOM_TELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOM_CHAT_ID_DNRM] [bigint] NULL,
[DAD_CELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DAD_TELL_PHON_DNRM] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DAD_CHAT_ID_DNRM] [bigint] NULL,
[DPST_ACNT_SLRY_BANK_DNRM] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DPST_ACNT_SLRY_DNRM] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTNG_NUMB_DNRM] [smallint] NULL,
[REF_CODE_DNRM] [bigint] NULL,
[LEFT_FILE_NO] [bigint] NULL,
[RIGH_FILE_NO] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_FIGH]
   ON  [dbo].[Fighter]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED) S
   ON (T.FILE_NO = S.FILE_NO)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,FILE_NO   = DBO.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_FIGH]
   ON  [dbo].[Fighter]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   /*
   IF EXISTS(
      SELECT * 
        FROM dbo.Fighter f, Inserted i
       WHERE f.FILE_NO != i.FILE_NO
         AND f.FNGR_PRNT_DNRM = i.FNGR_PRNT_DNRM
   )
   */
   
   -- 1400-02-04 * مشکلی که درون سیستم استخر بهاران بود که وقتی مهمان آزاد ثبت درخواست انجام میدادیم با مشکل مواجه مشد
   IF NOT EXISTS(SELECT * FROM Inserted)
      RETURN;
   
   -- 1401-02-29 * IF Member is Guest no need Update
   IF EXISTS(SELECT * FROM Inserted i WHERE i.FGPB_TYPE_DNRM = '005')
	  RETURN;
   
   -- Insert statements for trigger here
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED) S
   ON (T.FILE_NO = S.FILE_NO)
   WHEN MATCHED THEN
      UPDATE
         SET T.MDFY_BY        = UPPER(SUSER_NAME())
            ,T.MDFY_DATE      = GETDATE()
            ,T.CONF_DATE      = CASE 
                                    WHEN T.CONF_STAT = '002' AND S.CONF_STAT = '002' AND T.CONF_DATE IS NULL THEN GETDATE() 
                                    WHEN T.CONF_STAT = '002' AND T.CONF_DATE IS NOT NULL THEN T.CONF_DATE 
                                    WHEN T.CONF_STAT = '001' AND S.CONF_STAT = '001' THEN NULL 
                                END
            ,T.DEBT_DNRM      = CASE S.FGPB_TYPE_DNRM WHEN '005' THEN 0 ELSE dbo.GET_DBTF_U(S.FILE_NO) END
            --,T.BUFE_DEBT_DNTM = dbo.GET_DBBF_U(s.FILE_NO)
            --,T.TARF_CODE_DNRM = dbo.GET_TARF_U(S.File_No)
            ,T.DPST_AMNT_DNRM = CASE S.FGPB_TYPE_DNRM WHEN '005' THEN 0 ELSE dbo.GET_DPST_U(s.FILE_NO) END;
END;
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FIGH_PK] PRIMARY KEY CLUSTERED  ([FILE_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_CLUB] FOREIGN KEY ([CLUB_CODE_DNRM]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_CTGY] FOREIGN KEY ([CTGY_CODE_DNRM]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_FIGH] FOREIGN KEY ([REF_CODE_DNRM]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_MTOD] FOREIGN KEY ([MTOD_CODE_DNRM]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
ALTER TABLE [dbo].[Fighter] ADD CONSTRAINT [FK_FIGH_SUNT] FOREIGN KEY ([SUNT_BUNT_DEPT_ORGN_CODE_DNRM], [SUNT_BUNT_DEPT_CODE_DNRM], [SUNT_BUNT_CODE_DNRM], [SUNT_CODE_DNRM]) REFERENCES [dbo].[Sub_Unit] ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE]) ON UPDATE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'بدهی بوفه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'BUFE_DEBT_DNTM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت مشتریان جلسه ای', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'CARD_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ سپرده', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'DPST_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف جلسه خصوصی با مربی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'MBCO_RWNO_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد ملی', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'NATL_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد معرف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'REF_CODE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان رضایتمندی مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Fighter', 'COLUMN', N'RTNG_NUMB_DNRM'
GO
