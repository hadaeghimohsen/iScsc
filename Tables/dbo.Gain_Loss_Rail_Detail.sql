CREATE TABLE [dbo].[Gain_Loss_Rail_Detail]
(
[GLRL_GLID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[AMNT] [decimal] (18, 2) NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TERM_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRAN_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NO] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BANK] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FLOW_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REF_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_DATE] [datetime] NULL,
[SHOP_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RCPT_TO_OTHR_ACNT] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GLRD]
   ON  [dbo].[Gain_Loss_Rail_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Gain_Loss_Rail_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.GLRL_GLID = S.GLRL_GLID AND 
       T.RWNO = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Gain_Loss_Rail_Detail WHERE GLRL_GLID = S.GLRL_GLID);
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
CREATE TRIGGER [dbo].[CG$AUPD_GLRD]
   ON  [dbo].[Gain_Loss_Rail_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DECLARE @DpstAmnt BIGINT
          ,@Glid BIGINT;          
    
   SELECT @DpstAmnt = T.AMNT
         ,@Glid = T.GLID
     FROM dbo.Gain_Loss_Rial T, Inserted S
    WHERE T.GLID = S.GLRL_GLID;
   
   DECLARE @DpstAmntDtil BIGINT;      
   
   SELECT @DpstAmntDtil = SUM(AMNT)     
     FROM dbo.Gain_Loss_Rail_Detail
    WHERE GLRL_GLID = @Glid;
   
   -- بررسی اینکه آیا مقدار وارد شده از مبلغ سپرده بیشتر نباشد
   IF @DpstAmnt < @DpstAmntDtil
   BEGIN
      RAISERROR(N'مبلغ های وارد شده در جدول از مبلغ وارد شده در ستون مبلغ سپرده بیشتر می باشد. لطفا اصلاح کنید', 16, 1);
      RETURN;
   END
   
    -- Insert statements for trigger here
   MERGE dbo.Gain_Loss_Rail_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.GLRL_GLID = S.GLRL_GLID AND 
       T.RWNO = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();            
END
GO
ALTER TABLE [dbo].[Gain_Loss_Rail_Detail] ADD CONSTRAINT [PK_GLRD] PRIMARY KEY CLUSTERED  ([GLRL_GLID], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Gain_Loss_Rail_Detail] ADD CONSTRAINT [FK_GLRD_GLRL] FOREIGN KEY ([GLRL_GLID]) REFERENCES [dbo].[Gain_Loss_Rial] ([GLID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Gain_Loss_Rail_Detail] ADD CONSTRAINT [FK_GLRD_RCPT_APBS] FOREIGN KEY ([RCPT_TO_OTHR_ACNT]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE SET NULL
GO
