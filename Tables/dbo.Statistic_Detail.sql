CREATE TABLE [dbo].[Statistic_Detail]
(
[STIS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[STIS_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEX_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONT_NUMB] [bigint] NULL,
[SUM_EXPN_AMNT] [bigint] NULL,
[SUM_DSCT_AMNT] [bigint] NULL,
[SUM_CASH_AMNT] [bigint] NULL,
[SUM_POS_AMNT] [bigint] NULL,
[SUM_C2C_AMNT] [bigint] NULL,
[SUM_DPST_AMNT] [bigint] NULL,
[SUM_REMN_AMNT] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_STSD]
   ON  [dbo].[Statistic_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Statistic_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.STIS_CODE = S.STIS_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
         --T.RWNO = (SELECT ISNULL(MAX(sd.RWNO), 0) + 1 FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = s.STIS_CODE);
   
   DECLARE C$STSD CURSOR FOR
      SELECT sd.CODE, sd.STIS_CODE
        FROM dbo.Statistic_Detail sd
       WHERE sd.STIS_CODE IN (
                SELECT i.STIS_CODE
                  FROM Inserted i
             )
         AND sd.RWNO IS NULL
       ORDER BY sd.CRET_DATE DESC;
   
   DECLARE @Code BIGINT,
           @StisCode BIGINT;
   
   OPEN [C$STSD];
   L$Loop:
   FETCH [C$STSD] INTO @Code, @StisCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   UPDATE t
      SET RWNO = (SELECT ISNULL(MAX(sd.RWNO), 0) + 1 FROM dbo.Statistic_Detail sd WHERE sd.STIS_CODE = t.STIS_CODE)
     FROM dbo.Statistic_Detail t
    WHERE t.STIS_CODE = @StisCode
      AND t.CODE = @Code;
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$STSD];
   DEALLOCATE [C$STSD];
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
CREATE TRIGGER [dbo].[CG$AUPD_STSD]
   ON  [dbo].[Statistic_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Statistic_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.STIS_CODE = S.STIS_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();      
END
GO
ALTER TABLE [dbo].[Statistic_Detail] ADD CONSTRAINT [PK_STSD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Statistic_Detail] ADD CONSTRAINT [FK_STSD_STIS] FOREIGN KEY ([STIS_CODE]) REFERENCES [dbo].[Statistic] ([CODE]) ON DELETE CASCADE
GO
