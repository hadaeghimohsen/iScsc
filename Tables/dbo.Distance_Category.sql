CREATE TABLE [dbo].[Distance_Category]
(
[FRST_CTGY_CODE] [bigint] NOT NULL,
[SCND_CTGY_CODE] [bigint] NOT NULL,
[CYCL] [smallint] NOT NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_DSCT]
   ON  [dbo].[Distance_Category]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   IF EXISTS(
      SELECT *
        FROM Distance_Category dc, INSERTED I
       WHERE dc.FRST_CTGY_CODE = I.FRST_CTGY_CODE
         AND dc.SCND_CTGY_CODE <> i.SCND_CTGY_CODE
   )
   BEGIN
      RAISERROR ( N'خطا - یک رده کمربندی فقط با یک رده بعد از خود می تواند فاصله داشته باشد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   -- Insert statements for trigger here
   MERGE dbo.Distance_Category T
   USING (SELECT * FROM INSERTED) S
   ON (T.FRST_CTGY_CODE = S.FRST_CTGY_CODE AND
       T.SCND_CTGY_CODE = S.SCND_CTGY_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_DSCT]
   ON  [dbo].[Distance_Category]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Distance_Category T
   USING (SELECT * FROM INSERTED) S
   ON (T.FRST_CTGY_CODE = S.FRST_CTGY_CODE AND
       T.SCND_CTGY_CODE = S.SCND_CTGY_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;

GO
ALTER TABLE [dbo].[Distance_Category] ADD CONSTRAINT [PK_Distance_Category] PRIMARY KEY CLUSTERED  ([FRST_CTGY_CODE], [SCND_CTGY_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Distance_Category] ADD CONSTRAINT [FK_FDSC_CTGY] FOREIGN KEY ([FRST_CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Distance_Category] ADD CONSTRAINT [FK_SDSC_CTGY] FOREIGN KEY ([SCND_CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
