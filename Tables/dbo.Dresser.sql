CREATE TABLE [dbo].[Dresser]
(
[COMA_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DRES_NUMB] [int] NULL,
[DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Dresser_REC_STAT] DEFAULT ('002'),
[ORDR] [int] NULL,
[CMND_SEND] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMM_PORT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BAND_RATE] [int] NULL,
[IP_ADRS] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_DRES]
   ON  [dbo].[Dresser]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = dbo.Gnrt_Nvid_U()
            ,DRES_NUMB = CASE WHEN S.DRES_NUMB = 0 OR S.DRES_NUMB IS NULL  THEN (SELECT COUNT(Code) FROM Dresser WHERE COMA_CODE = S.COMA_CODE) ELSE S.DRES_NUMB END;
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_DRES]
   ON  [dbo].[Dresser]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,[DESC] = CASE WHEN LEN(S.[DESC]) = 0 THEN N'No ' + CAST(S.DRES_NUMB AS VARCHAR(10)) ELSE S.[DESC] END;
END
;
GO
ALTER TABLE [dbo].[Dresser] ADD CONSTRAINT [PK_DRES] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Dresser] ADD CONSTRAINT [FK_COMA_DRES] FOREIGN KEY ([COMA_CODE]) REFERENCES [dbo].[Computer_Action] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'دستور ارسال به کمد', 'SCHEMA', N'dbo', 'TABLE', N'Dresser', 'COLUMN', N'CMND_SEND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح', 'SCHEMA', N'dbo', 'TABLE', N'Dresser', 'COLUMN', N'DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کمد', 'SCHEMA', N'dbo', 'TABLE', N'Dresser', 'COLUMN', N'DRES_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ترتیب باز شدن کمد', 'SCHEMA', N'dbo', 'TABLE', N'Dresser', 'COLUMN', N'ORDR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت کمد', 'SCHEMA', N'dbo', 'TABLE', N'Dresser', 'COLUMN', N'REC_STAT'
GO
