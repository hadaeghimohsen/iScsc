CREATE TABLE [dbo].[Receive_Document]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[RQDC_RDID] [bigint] NULL,
[RCID] [bigint] NOT NULL CONSTRAINT [DF_RCDC_RCID] DEFAULT ((0)),
[DELV_DATE] [datetime] NULL,
[RCDC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PERM_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [date] NULL,
[END_DATE] [date] NULL,
[RCDC_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_RCDC]
   ON  [dbo].[Receive_Document]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Receive_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RQDC_RDID      = S.RQDC_RDID)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RCID      = Dbo.GNRT_NVID_U();
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_RCDC]
   ON  [dbo].[Receive_Document]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Receive_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RQDC_RDID      = S.RQDC_RDID      AND
       T.RCID           = S.RCID)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();  
            
   DECLARE C$RCDC CURSOR FOR
      SELECT S.RCID
        FROM INSERTED S;
   DECLARE @Rcid BIGINT;
           
   OPEN C$RCDC;
   NEXTC$RCDC:
   FETCH NEXT FROM C$RCDC INTO @Rcid;
   
   IF @@FETCH_STATUS <> 0
      GOTO ENDC$RCDC;
   
   IF NOT EXISTS(SELECT * FROM Image_Document WHERE RCDC_RCID = @Rcid)
      INSERT INTO Image_Document (RCDC_RCID) 
      VALUES (@Rcid);
   
   GOTO NEXTC$RCDC;
   ENDC$RCDC:
   CLOSE C$RCDC;
   DEALLOCATE C$RCDC;        
END
GO
ALTER TABLE [dbo].[Receive_Document] ADD CONSTRAINT [RCDC_PK] PRIMARY KEY CLUSTERED  ([RCID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Receive_Document] ADD CONSTRAINT [FK_RCDC_RQDC] FOREIGN KEY ([RQDC_RDID]) REFERENCES [dbo].[Request_Document] ([RDID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Receive_Document] ADD CONSTRAINT [FK_RCDC_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE SET NULL
GO
