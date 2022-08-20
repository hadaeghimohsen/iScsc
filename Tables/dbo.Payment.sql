CREATE TABLE [dbo].[Payment]
(
[REGL_YEAR_DNRM] [smallint] NULL,
[REGL_CODE_DNRM] [int] NULL,
[CASH_CODE] [bigint] NOT NULL,
[RQST_RQID] [bigint] NOT NULL,
[YEAR] [smallint] NULL,
[CYCL] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYMT_NO] [int] NULL,
[PYMT_PYMT_NO] [int] NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment__TYPE__02FC7413] DEFAULT ('001'),
[PYMT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_PYMT_TYPE] DEFAULT ('001'),
[PYMT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_PYMT_STAT] DEFAULT ('001'),
[RECV_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment__RECV_TY__03F0984C] DEFAULT ('001'),
[SUM_EXPN_PRIC] [bigint] NOT NULL CONSTRAINT [DF__Payment__SUM_EXP__04E4BC85] DEFAULT ((0)),
[SUM_EXPN_EXTR_PRCT] [bigint] NOT NULL CONSTRAINT [DF__Payment__SUM_EXP__05D8E0BE] DEFAULT ((0)),
[SUM_REMN_PRIC] [bigint] NOT NULL CONSTRAINT [DF__Payment__SUM_REM__06CD04F7] DEFAULT ((0)),
[SUM_RCPT_EXPN_PRIC] [bigint] NULL CONSTRAINT [DF__Payment__SUM_RCP__07C12930] DEFAULT ((0)),
[SUM_RCPT_EXPN_EXTR_PRCT] [bigint] NULL CONSTRAINT [DF__Payment__SUM_RCP__08B54D69] DEFAULT ((0)),
[SUM_RCPT_REMN_PRIC] [bigint] NULL CONSTRAINT [DF__Payment__SUM_RCP__09A971A2] DEFAULT ((0)),
[SUM_PYMT_DSCN_DNRM] [bigint] NULL CONSTRAINT [DF_Payment_SUM_PYMT_DSCN_DNRM] DEFAULT ((0)),
[CASH_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CASH_DATE] [datetime] NULL,
[ANNC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__Payment__ANNC_TY__0A9D95DB] DEFAULT ('001'),
[ANNC_DATE] [datetime] NULL,
[LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LETT_DATE] [datetime] NULL,
[DELV_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_DELV_STAT] DEFAULT ((1)),
[DELV_DATE] [datetime] NULL,
[DELV_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_CODE_DNRM] [bigint] NULL,
[AMNT_UNIT_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LOCK_DATE] [datetime] NULL,
[PROF_AMNT_DNRM] [bigint] NULL,
[DEDU_AMNT_DNRM] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_PYMT]
   ON  [dbo].[Payment]
   AFTER DELETE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   IF (SELECT COUNT(*) FROM Deleted d, dbo.Request r WHERE r.RQID = d.RQST_RQID AND r.RQST_STAT = '002') = 1
   BEGIN
      -- 1396/10/05 * ثبت پیامک       	
      IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '018' AND STAT = '002')
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@LineType VARCHAR(3)
                ,@Cel1Phon VARCHAR(11)
                ,@Cel2Phon VARCHAR(11)
                ,@Cel3Phon VARCHAR(11)
                ,@Cel4Phon VARCHAR(11)
                ,@Cel5Phon VARCHAR(11)
                ,@AmntType VARCHAR(3)
                ,@AmntTypeDesc NVARCHAR(255);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@LineType = LINE_TYPE
               ,@Cel1Phon = CEL1_PHON
               ,@Cel2Phon = CEL2_PHON
               ,@Cel3Phon = CEL3_PHON
               ,@Cel4Phon = CEL4_PHON
               ,@Cel5Phon = CEL5_PHON            
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '018';
         
 	      SELECT @AmntType = rg.AMNT_TYPE, 
	             @AmntTypeDesc = d.DOMN_DESC
	        FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
	       WHERE rg.TYPE = '001'
	         AND rg.REGL_STAT = '002'
	         AND rg.AMNT_TYPE = d.VALU;
         
         SELECT @MsgbText = (
            SELECT N'حذف کامل صورتحساب' + CHAR(10) +
                   rt.RQTP_DESC + CHAR(10) + 
                   N'تاریخ تایید درخواست ' + dbo.GET_MTST_U(r.SAVE_DATE) + CHAR(10) +
                   N'نام مشترک ' + f.NAME_DNRM + CHAR(10) + 
                   N'صورتحساب ' + CHAR(10) + 
                   N'مبلغ کل دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, d.SUM_EXPN_PRIC + d.SUM_EXPN_EXTR_PRCT), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                   N'مبلغ تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, d.SUM_PYMT_DSCN_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                   N'مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, d.SUM_RCPT_EXPN_PRIC), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                   N'مبلغ بدهی دوره ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, (d.SUM_EXPN_PRIC + d.SUM_EXPN_EXTR_PRCT) - (d.SUM_PYMT_DSCN_DNRM + d.SUM_RCPT_EXPN_PRIC)), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(10) +
                   N'کاربر : ' + UPPER(SUSER_NAME()) + CHAR(10) + 
                   N'تاریخ : ' + dbo.GET_MTST_U(GETDATE())
              FROM Deleted d,
                   dbo.Request_Type rt,
                   dbo.Request r,
                   dbo.Request_Row rr,
                   dbo.Fighter f
             WHERE d.RQST_RQID = r.RQID
               AND r.RQTP_CODE = rt.CODE
               AND r.RQID = rr.RQST_RQID
               AND rr.FIGH_FILE_NO = f.FILE_NO
         );          
         
         IF @MsgbStat = '002' 
         BEGIN
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      @LineType AS '@linetype',
                      (
                        SELECT @Cel1Phon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
  SELECT @Cel2Phon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel3Phon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel4Phon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      ),
                      (
                        SELECT @Cel5Phon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )                   
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml                  
         END;
      END;
   END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_PYMT]
   ON  [dbo].[Payment]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- 1398/10/01 * اگر درخواست پایانی شد شماره ردیف صورتحساب را وارد میکنیم 
   DECLARE @PymtNo INT = 1
          ,@FileNo BIGINT;
   
   SELECT @FileNo = rr.FIGH_FILE_NO
     FROM dbo.Request_Row rr, Inserted i
    WHERE rr.RQST_RQID = i.RQST_RQID;
    
   SELECT @PymtNo = COUNT(r.RQID) + 1
     FROM dbo.Request r, dbo.Request_Row rr, dbo.Payment p
    WHERE r.RQID = p.RQST_RQID
      AND r.RQID = rr.RQST_RQID
      AND r.RQST_STAT = '002'         
      AND rr.FIGH_FILE_NO IN ( @FileNo );
      
   -- Insert statements for trigger here
   MERGE dbo.Payment T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.CASH_CODE = S.CASH_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,YEAR      = SUBSTRING(DBO.GET_MTOS_U(GETDATE()), 1, 4)
            ,CYCL      = '0' + SUBSTRING(DBO.GET_MTOS_U(GETDATE()), 6, 2)
            ,T.PYMT_NO = CASE WHEN @PymtNo IS NOT NULL THEN @PymtNo ELSE 1 END
            ,DELV_STAT = '001'            
            ,CLUB_CODE_DNRM = 
            CASE WHEN (
				   SELECT TOP 1 CLUB_CODE 
				     FROM Fighter_Public F 
				    WHERE F.Rqro_Rqst_Rqid = S.Rqst_Rqid) IS NOT NULL THEN (
				      SELECT TOP 1 CLUB_CODE 
				        FROM Fighter_Public F 
				       WHERE F.Rqro_Rqst_Rqid = S.Rqst_Rqid)
				    ELSE (
				      SELECT F.Club_Code_Dnrm
				        FROM Fighter F
				       WHERE F.Rqst_Rqid = S.Rqst_Rqid
				    )
				 END
				,T.AMNT_UNIT_TYPE_DNRM = (
				   SELECT ISNULL(AMNT_TYPE, '001')
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				)
				,T.LOCK_DATE = DATEADD(DAY, 30, GETDATE())
				,T.REGL_YEAR_DNRM = (
				   SELECT YEAR
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				)
				,T.REGL_CODE_DNRM = (
				   SELECT CODE
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				);
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PYMT]
   ON  [dbo].[Payment]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   IF EXISTS(
      SELECT * FROM DELETED D, INSERTED I
      WHERE D.RQST_RQID = I.RQST_RQID
        AND D.TYPE      <> I.TYPE
   )
   BEGIN
      RAISERROR ('مبلغ اعلام هزینه شده از حالت واریز وجه به حالت استرداد وجه و برعکس امکان پذیر نمی باشد', -- Message text.
         16, -- Severity.
         1 -- State.
         );
      ROLLBACK TRANSACTION;
   END;   
   
   -- 1396/03/04 * تاریخ و زمانی که هزینه قفل شده بعدا در سیستم لحاظ گردد   
   MERGE dbo.Payment T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND 
       T.CASH_CODE = S.CASH_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,CASH_BY   = CASE WHEN S.SUM_EXPN_PRIC = (ISNULL(S.SUM_RCPT_EXPN_PRIC, 0) + S.SUM_PYMT_DSCN_DNRM) AND S.Cash_By IS NULL THEN SUSER_NAME() WHEN S.Cash_By IS NULL THEN NULL ELSE S.Cash_By END
            ,CASH_DATE = CASE WHEN S.SUM_EXPN_PRIC = (ISNULL(S.SUM_RCPT_EXPN_PRIC, 0) + S.SUM_PYMT_DSCN_DNRM) AND S.Cash_Date IS NULL THEN GETDATE()  WHEN S.Cash_Date IS NULL THEN NULL ELSE S.Cash_Date END;            
            /*,SUM_EXPN_PRIC = S.SUM_EXPN_PRIC - ISNULL(S.SUM_PYMT_DSCN_DNRM, 0)*/;
   
   IF EXISTS(
       SELECT *
         FROM dbo.Payment_Method pm, Inserted i
        WHERE pm.PYMT_RQST_RQID = i.RQST_RQID
   ) OR 
   EXISTS(
       SELECT *
         FROM dbo.Payment_Discount pd, Inserted i
        WHERE pd.PYMT_RQST_RQID = i.RQST_RQID
          AND pd.STAT = '002'
   )
   BEGIN
      UPDATE p
         SET p.SUM_RCPT_EXPN_PRIC = (SELECT ISNULL(SUM(pm.AMNT), 0) FROM dbo.Payment_Method pm WHERE pm.PYMT_RQST_RQID = p.RQST_RQID)
            ,p.SUM_PYMT_DSCN_DNRM = (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = p.RQST_RQID)
        FROM dbo.Payment p, Inserted i
       WHERE p.RQST_RQID = i.RQST_RQID
   END;
   
   -- 1396/08/02 * برای آن دسته از درخواست هایی که مشتری کل پرداختی هزینه خود را پرداخت کرده به صورت اتوماتیک وضعیت هزینه پرداخت شده ثبت کنیم     
   -- 1398/10/02 * بازسازی دستور کامنت شده
   --IF EXISTS(
   --   SELECT *
   --     FROM dbo.Payment p , Inserted i, dbo.Request r
   --    WHERE p.RQST_RQID = i.RQST_RQID
   --      AND p.CASH_CODE = i.CASH_CODE
   --      AND r.RQID = p.RQST_RQID
   --      AND r.RQST_STAT = '002'
   --      AND (p.SUM_EXPN_PRIC + ISNULL(p.SUM_EXPN_EXTR_PRCT, 0) - (ISNULL(p.SUM_RCPT_EXPN_PRIC, 0) + ISNULL(p.SUM_PYMT_DSCN_DNRM, 0))) = 0
   --)
   --BEGIN   
   --   DISABLE TRIGGER ALL ON dbo.Payment_Detail;
   --   --ALTER TABLE dbo.Payment_Detail DISABLE TRIGGER [CG$AUPD_PMDT];
   --   PRINT 'Disabled 1'
   --   UPDATE pd
   --      SET pd.PAY_STAT = '002'
   --         ,pd.DOCM_NUMB = i.CASH_CODE
   --         ,pd.ISSU_DATE = GETDATE()
   --     FROM dbo.Payment_Detail pd, Inserted i
   --    WHERE pd.PYMT_RQST_RQID = i.RQST_RQID
   --      AND pd.PYMT_CASH_CODE = i.CASH_CODE
   --      AND PAY_STAT = '001';
   --   ENABLE TRIGGER ALL ON dbo.Payment_Detail;
   --   PRINT 'Enabled 1'
   --END
   --ELSE IF EXISTS(
   --   SELECT *
   --     FROM dbo.Payment p , Inserted i, dbo.Request r
   --    WHERE p.RQST_RQID = i.RQST_RQID
   --      AND p.CASH_CODE = i.CASH_CODE
   --      AND r.RQID = p.RQST_RQID
   --      AND r.RQST_STAT = '002'
   --      AND (p.SUM_EXPN_PRIC + ISNULL(p.SUM_EXPN_EXTR_PRCT, 0) - (ISNULL(p.SUM_RCPT_EXPN_PRIC, 0) + ISNULL(p.SUM_PYMT_DSCN_DNRM, 0))) != 0
   --)
   --BEGIN
   --   DISABLE TRIGGER ALL ON dbo.Payment_Detail;
   --   --ALTER TABLE dbo.Payment_Detail DISABLE TRIGGER [CG$AUPD_PMDT];
   --   PRINT 'Disabled 2'
   --   UPDATE pd
   --      SET pd.PAY_STAT = '001'
   --         ,pd.DOCM_NUMB = i.CASH_CODE
   --         ,pd.ISSU_DATE = GETDATE()
   --     FROM dbo.Payment_Detail pd, Inserted i
   --    WHERE pd.PYMT_RQST_RQID = i.RQST_RQID
   --      AND pd.PYMT_CASH_CODE = i.CASH_CODE
   --      AND PAY_STAT = '002';
   --   ENABLE TRIGGER ALL ON dbo.Payment_Detail;
   --   PRINT 'Enabled 2'
   --END 
END
;
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [PYMT_PK] PRIMARY KEY CLUSTERED  ([CASH_CODE], [RQST_RQID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_CASH] FOREIGN KEY ([CASH_CODE]) REFERENCES [dbo].[Cash] ([CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_CLUB] FOREIGN KEY ([CLUB_CODE_DNRM]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_REGL] FOREIGN KEY ([REGL_YEAR_DNRM], [REGL_CODE_DNRM]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد پولی', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'AMNT_UNIT_TYPE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ های کسر شده', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'DEDU_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان تغییرات هزینه ای', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'LOCK_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ سود نهایی', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'PROF_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت صورتحساب', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'PYMT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع صورتحساب صادر شده', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'PYMT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع صورتحساب با بار مثبت یا منفی

واریز وجه به عنوان درآمد
استرداد وجه به عنوان هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'TYPE'
GO
