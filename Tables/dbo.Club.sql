CREATE TABLE [dbo].[Club]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Club_REGN_PRVN_CNTY_CODE] DEFAULT ('001'),
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Club_REGN_PRVN_CODE] DEFAULT ('001'),
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_CLUB_CODE] DEFAULT ((0)),
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[POST_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EMAL_ADRS] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_SITE] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[TELL_PHON] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_CODE] [bigint] NULL,
[ZIP_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ECON_CODE] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CLUB]
   ON  [dbo].[Club]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   -- چک کردن تعداد نسخه های نرم افزار خریداری شده
   /*IF (SELECT COUNT(*) FROM Club) > dbo.NumberInstanceForUser()
   BEGIN
      RAISERROR(N'با توجه به تعداد نسخه خریداری شده شما قادر به اضافه کردن مکان جدید به نرم افزار را ندارید. لطفا با پشتیبانی 09333617031 تماس بگیرید', 16, 1);
      RETURN;
   END*/
   
   MERGE dbo.Club T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE AND
       T.REGN_PRVN_CODE      = S.REGN_PRVN_CODE      AND
       T.REGN_CODE           = S.REGN_CODE           AND
       T.CODE                = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = dbo.Gnrt_Nvid_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CLUB]
   ON  [dbo].[Club]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Club T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE AND
       T.REGN_PRVN_CODE      = S.REGN_PRVN_CODE      AND
       T.REGN_CODE           = S.REGN_CODE           AND
       T.CODE                = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
   
   
   MERGE dbo.Settings T
   USING (SELECT * FROM Inserted) S
   ON (T.CLUB_CODE = s.CODE)
   WHEN NOT MATCHED THEN 
      INSERT ( CLUB_CODE, CODE ,DFLT_STAT ,BACK_UP ,BACK_UP_APP_EXIT ,BACK_UP_IN_TRED ,
               BACK_UP_OPTN_PATH ,BACK_UP_OPTN_PATH_ADRS ,BACK_UP_ROOT_PATH ,DRES_STAT ,
               DRES_AUTO ,MORE_FIGH_ONE_DRES ,MORE_ATTN_SESN ,NOTF_STAT ,NOTF_EXP_DAY ,
               NOTF_VIST_DATE ,ATTN_SYST_TYPE ,COMM_PORT_NAME ,BAND_RATE ,BAR_CODE_DATA_TYPE ,
               ATN3_EVNT_ACTN_TYPE ,IP_ADDR ,PORT_NUMB ,ATTN_COMP_CONCT ,ATN1_EVNT_ACTN_TYPE ,
               IP_ADR2 ,PORT_NUM2 ,ATTN_COMP_CNC2 ,ATN2_EVNT_ACTN_TYPE ,ATTN_NOTF_STAT ,
               ATTN_NOTF_CLOS_TYPE ,ATTN_NOTF_CLOS_INTR ,DEBT_CLNG_STAT ,MOST_DEBT_CLNG_AMNT ,
               EXPR_DEBT_DAY ,TRY_VALD_SBMT ,DEBT_CHCK_STAT ,GATE_ATTN_STAT ,GATE_COMM_PORT_NAME ,
               GATE_BAND_RATE ,GATE_TIME_CLOS ,GATE_ENTR_OPEN ,GATE_EXIT_OPEN ,EXPN_EXTR_STAT ,
               EXPN_COMM_PORT_NAME ,EXPN_BAND_RATE ,RUN_QURY ,ATTN_PRNT_STAT ,SHAR_MBSP_STAT ,
               RUN_RBOT ,HLDY_CONT ,CLER_ZERO
             )
      VALUES (S.CODE, dbo.GNRT_NVID_U() , '002' , NULL , NULL , 
          NULL , NULL , N'' , N'' , '' , 
          '' , '001' , '001' , '' , 0 , GETDATE() , 
          '000' , '' , 9600 , '002' , 
          '' , '' , 4370 , '' , '' , 
          '' , 4370 , '' , '' , '002' , 
          '' , 0 , '001' , 0 , 
          0 , '002' , '001' , '001' , '' , 
          9600 , 0 , '' , '' , '001' , 
          '' , 9600 , '002' , '001' , '001' , 
          '001' , 0 , '001' );
   
END
;
GO
ALTER TABLE [dbo].[Club] ADD CONSTRAINT [CLUB_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Club] ADD CONSTRAINT [FK_CLUB_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Club] ADD CONSTRAINT [FK_CLUB_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON UPDATE CASCADE
GO
