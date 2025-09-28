CREATE TABLE [dbo].[Card_Link_Operation_Detail]
(
[CLOP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CLOP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLOP_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CLOD]
   ON  [dbo].[Card_Link_Operation_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Card_Link_Operation_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.CLOP_CODE = S.CLOP_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.CLOP_DATE = GETDATE();
   
   -- این گزینه برای مشخص شدن تعداد دفعاتی که کارت برای باز و بسته شدن روی دستگاه های ریدر ورودی و خروجی گذاشته شده مورد استفاده قرار میگیرد
   WITH TotalCalc AS (
      SELECT SUM(CASE WHEN cd.CLOP_TYPE = '001' THEN 1 ELSE 0 END) AS TOTL_OPEN_DNRM,
             SUM(CASE WHEN cd.CLOP_TYPE = '002' THEN 1 ELSE 0 END) AS TOTL_CLOS_DNRM,
             cd.CLOP_CODE
        FROM dbo.Card_Link_Operation_Detail cd, Inserted i
       WHERE cd.CLOP_CODE = i.CLOP_CODE
       GROUP BY cd.CLOP_CODE
   )
   UPDATE c
      SET c.TOTL_OPEN_DNRM = t.TOTL_OPEN_DNRM,
          c.TOTL_CLOS_DNRM = t.TOTL_CLOS_DNRM
     FROM dbo.Card_Link_Operation c, TotalCalc t
    WHERE c.CODE = t.CLOP_CODE;
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
CREATE TRIGGER [dbo].[CG$AUPD_CLOD]
   ON  [dbo].[Card_Link_Operation_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Card_Link_Operation_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Card_Link_Operation_Detail] ADD CONSTRAINT [PK_Card_Link_Operation_Detail] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Card_Link_Operation_Detail] ADD CONSTRAINT [FK_Card_Link_Operation_Detail_Card_Link_Operation] FOREIGN KEY ([CLOP_CODE]) REFERENCES [dbo].[Card_Link_Operation] ([CODE]) ON DELETE CASCADE
GO
