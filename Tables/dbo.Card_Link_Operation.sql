CREATE TABLE [dbo].[Card_Link_Operation]
(
[CARD_FILE_NO] [bigint] NULL,
[ATTN_CODE] [bigint] NULL,
[RQST_RQID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CARD_FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FIGH_FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TOTL_USE_MINT_DNRM] [int] NULL,
[STRT_TIME] [datetime] NULL,
[END_TIME] [datetime] NULL,
[TOTL_MINT_DNRM] [int] NULL,
[TOTL_EXPN_AMNT_DNRM] [bigint] NULL,
[EXPN_NUMB_ATTN_DNRM] [int] NULL,
[EXPN_1ATN_AMNT_DNRM] [int] NULL,
[EXPN_1MIN_AMNT_DNRM] [bigint] NULL,
[FINE_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FINE_MINT_DNRM] [int] NULL,
[FINE_AMNT_DNRM] [bigint] NULL,
[FINE_RQST_RQID] [bigint] NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TOTL_OPEN_DNRM] [int] NULL,
[TOTL_CLOS_DNRM] [int] NULL,
[EDEV_CODE] [bigint] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_CLOP]
   ON  [dbo].[Card_Link_Operation]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.[Card_Link_Operation] T
   USING (SELECT * FROM Inserted) S
   ON (T.CARD_FILE_NO = S.CARD_FILE_NO AND 
       ISNULL(T.ATTN_CODE, 0) = ISNULL(S.ATTN_CODE, 0) AND 
       ISNULL(t.RQST_RQID, 0) = ISNULL(s.RQST_RQID, 0) AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = dbo.GET_HOST_U(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.VALD_TYPE = '002',
         T.CARD_FNGR_PRNT_DNRM = (SELECT c.FNGR_PRNT_DNRM FROM dbo.Fighter c WHERE c.FILE_NO = s.CARD_FILE_NO),
         T.FIGH_FNGR_PRNT_DNRM = (CASE 
                                   WHEN s.ATTN_CODE IS NOT NULL THEN (SELECT a.FNGR_PRNT_DNRM FROM dbo.Attendance a WHERE a.CODE = s.ATTN_CODE) 
                                   WHEN s.RQST_RQID IS NOT NULL THEN (SELECT f.FNGR_PRNT_DNRM FROM dbo.Request_Row rr, dbo.Fighter f WHERE rr.RQST_RQID = s.RQST_RQID AND rr.FIGH_FILE_NO = f.FILE_NO)
                                  END),
         t.TOTL_USE_MINT_DNRM  = (CASE 
                                   WHEN s.ATTN_CODE IS NOT NULL THEN (SELECT cm.CLAS_TIME FROM dbo.Attendance a, dbo.Club_Method cm WHERE a.CODE = s.ATTN_CODE AND a.CBMT_CODE_DNRM = cm.CODE)
                                   WHEN s.RQST_RQID IS NOT NULL THEN (SELECT SUM(DATEPART(HOUR, e.MIN_TIME) * 60 + DATEPART(MINUTE, e.MIN_TIME)) FROM dbo.Payment_Detail pd, dbo.Expense e WHERE pd.PYMT_RQST_RQID = s.RQST_RQID AND pd.EXPN_CODE = e.CODE AND CAST(e.MIN_TIME AS TIME(0)) != '00:01:00')
                                  END);
                                  
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
CREATE TRIGGER [dbo].[CG$AUPD_CLOP]
   ON  [dbo].[Card_Link_Operation]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.[Card_Link_Operation] T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = dbo.GET_HOST_U(),
         T.TOTL_MINT_DNRM = CASE WHEN s.END_TIME IS NOT NULL THEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) ELSE NULL END,
         T.FINE_STAT = CASE WHEN s.END_TIME IS NOT NULL THEN CASE WHEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) > s.TOTL_USE_MINT_DNRM THEN '002' ELSE '001' END ELSE s.FINE_STAT END,
         T.FINE_MINT_DNRM = CASE WHEN s.END_TIME IS NOT NULL THEN CASE WHEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) > s.TOTL_USE_MINT_DNRM THEN (DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) - s.TOTL_USE_MINT_DNRM) ELSE NULL END ELSE s.FINE_MINT_DNRM END,
         T.FINE_AMNT_DNRM = CASE WHEN s.END_TIME IS NOT NULL AND S.FINE_STAT = '002' THEN S.EXPN_1MIN_AMNT_DNRM * S.FINE_MINT_DNRM ELSE NULL END,
         T.TOTL_EXPN_AMNT_DNRM = CASE 
                                    WHEN s.STRT_TIME IS NOT NULL THEN 
                                       CASE 
                                          WHEN s.ATTN_CODE IS NOT NULL THEN (SELECT cb.PRIC FROM dbo.Category_Belt cb, dbo.Attendance a WHERE a.CODE = s.ATTN_CODE AND a.CTGY_CODE_DNRM = cb.CODE)  
                                          WHEN s.RQST_RQID IS NOT NULL THEN (SELECT SUM(pd.EXPN_PRIC) FROM dbo.Payment_Detail pd, dbo.Expense e WHERE pd.PYMT_RQST_RQID = s.RQST_RQID AND pd.EXPN_CODE = e.CODE AND CAST(e.MIN_TIME AS TIME(0)) != '00:01:00')
                                       END
                                    ELSE NULL 
                                 END,
         T.EXPN_NUMB_ATTN_DNRM = CASE 
                                    WHEN S.ATTN_CODE IS NOT NULL THEN (SELECT a.NUMB_OF_ATTN_MONT FROM dbo.Attendance a WHERE a.CODE = s.ATTN_CODE)
                                    WHEN s.RQST_RQID IS NOT NULL THEN 1
                                 END,
         T.EXPN_1ATN_AMNT_DNRM = CASE 
                                    WHEN s.STRT_TIME IS NOT NULL THEN (s.TOTL_EXPN_AMNT_DNRM / s.EXPN_NUMB_ATTN_DNRM)
                                    ELSE NULL
                                 END,
         T.EXPN_1MIN_AMNT_DNRM = CASE 
                                    WHEN s.STRT_TIME IS NOT NULL THEN (s.EXPN_1ATN_AMNT_DNRM / s.TOTL_USE_MINT_DNRM)
                                    ELSE NULL
                                 END;
                                 
      IF EXISTS(SELECT * FROM Inserted i, Deleted d WHERE i.VALD_TYPE = '001' AND d.VALD_TYPE = '002')
      BEGIN
         INSERT dbo.Card_Link_Operation_Detail ( CLOP_CODE ,CODE ,CLOP_TYPE )
	      SELECT i.CODE, dbo.GNRT_NVID_U(), '002' FROM Inserted i;
	      
	      -- ثبت خروج مشتری
	      UPDATE a
	         SET a.EXIT_TIME = GETDATE()
	        FROM Inserted i, dbo.Attendance a
	       WHERE i.ATTN_CODE = a.CODE
	         AND a.EXIT_TIME IS NULL;
      END;
END;
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [PK_Card_Link_Opeartion] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [FK_Card_Link_Operation_Attendance] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE])
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [FK_Card_Link_Operation_External_Device] FOREIGN KEY ([EDEV_CODE]) REFERENCES [dbo].[External_Device] ([CODE])
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [FK_Card_Link_Operation_Fighter] FOREIGN KEY ([CARD_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [FK_Card_Link_Operation_Request] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
ALTER TABLE [dbo].[Card_Link_Operation] ADD CONSTRAINT [FK_Card_Link_Operation_Request1] FOREIGN KEY ([FINE_RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت مجموعه', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'CARD_FNGR_PRNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال پیام به دستگاه مورد نظر مثلا گیت خروجی برای خروج مشتری بعد از پرداخت جریمه یا خروج به موقع', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'EDEV_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه تک جلسه مورد استفاده مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'EXPN_1ATN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه هر دقیقه از آن آیتم مورد استفاده مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'EXPN_1MIN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد کل جلسات خریداری شده مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'EXPN_NUMB_ATTN_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ جریمه دیرکرد', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'FINE_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درخواست جریمه درآمد متفرقه', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'FINE_RQST_RQID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت جریمه دیرکرد', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'FINE_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه کل آیتمی که مشتری انتخاب کرده', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'TOTL_EXPN_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کل دقیقه ورود و خروج', 'SCHEMA', N'dbo', 'TABLE', N'Card_Link_Operation', 'COLUMN', N'TOTL_MINT_DNRM'
GO
