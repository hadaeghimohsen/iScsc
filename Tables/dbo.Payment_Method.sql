CREATE TABLE [dbo].[Payment_Method]
(
[PYMT_CASH_CODE] [bigint] NOT NULL,
[PYMT_RQST_RQID] [bigint] NOT NULL,
[RQRO_RQST_RQID] [bigint] NOT NULL,
[RQRO_RWNO] [smallint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[FIGH_FILE_NO_DNRM] [bigint] NULL,
[AMNT] [bigint] NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_Method_RCPT_MTOD] DEFAULT ('001'),
[TERM_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRAN_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NO] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BANK] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FLOW_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REF_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_DATE] [datetime] NULL,
[SHOP_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RCPT_TO_OTHR_ACNT] [bigint] NULL,
[RCPT_FILE_PATH] [nvarchar] (260) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$ADEL_PMTD] ON [dbo].[Payment_Method]
    AFTER DELETE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
    SET NOCOUNT ON;
   
   -- 1395/12/27 * بروز رسانی جدول هزینه برای ستون جمع مبلغ های دریافتی مشترک
   --MERGE dbo.Payment T
   --USING (SELECT * FROM Deleted )S
   --ON (T.CASH_CODE = S.PYMT_CASH_CODE AND 
   --    T.RQST_RQID = S.PYMT_RQST_RQID)
   --WHEN MATCHED THEN
   --   UPDATE SET
   --      T.SUM_RCPT_EXPN_PRIC = (
   --         SELECT SUM(Amnt) 
   --           FROM dbo.Payment_Method
   --          WHERE PYMT_CASH_CODE = S.PYMT_CASH_CODE
   --            AND PYMT_RQST_RQID = S.PYMT_RQST_RQID
   --      );
    UPDATE  Payment
    SET     SUM_RCPT_EXPN_PRIC = ( SELECT   ISNULL(SUM(ISNULL(AMNT, 0)), 0)
                                   FROM     dbo.Payment_Method Pd
                                   WHERE    Pd.PYMT_CASH_CODE = CASH_CODE
                                            AND Pd.PYMT_RQST_RQID = RQST_RQID
                                 )
         /*,SUM_EXPN_PRIC = ROUND((   
            SELECT ISNULL(SUM(EXPN_PRIC * QNTY), 0)
              FROM Payment_Detail 
             WHERE PYMT_RQST_RQID = RQST_RQID
               AND PYMT_CASH_CODE = Cash_Code
      ), -3)*/
    WHERE   EXISTS ( SELECT *
                     FROM   DELETED S
                     WHERE  S.PYMT_CASH_CODE = CASH_CODE
                            AND S.PYMT_RQST_RQID = RQST_RQID );
   
   -- بروز کردن مبلغ بدهی هنرجو
    UPDATE  dbo.Fighter
    SET     CONF_STAT = CONF_STAT
    WHERE   FILE_NO IN ( SELECT FIGH_FILE_NO
                         FROM   dbo.Request_Row Rr ,
                                Deleted I
                         WHERE  Rr.RQST_RQID = I.PYMT_RQST_RQID );
    
    -- 1398/06/30 * ثبت پیامک
    IF EXISTS ( SELECT  *
                FROM    dbo.Message_Broadcast
                WHERE   MSGB_TYPE = '030'
                        AND STAT = '002' )
    BEGIN
        DECLARE @MsgbStat VARCHAR(3) ,
            @MsgbText NVARCHAR(MAX) ,
            @TempMsgbText NVARCHAR(MAX) ,
            @InsrCnamStat VARCHAR(3) ,
            @ClubName NVARCHAR(250) ,
            @XMsg XML ,
            @LineType VARCHAR(3) ,
            @CellPhon VARCHAR(11) ,
            @Cel1Phon VARCHAR(11) ,
            @Cel2Phon VARCHAR(11) ,
            @Cel3Phon VARCHAR(11) ,
            @Cel4Phon VARCHAR(11) ,
            @Cel5Phon VARCHAR(11) ,
            @AmntType VARCHAR(3) ,
            @AmntTypeDesc NVARCHAR(255);
                      
        SELECT  @MsgbStat = STAT ,
                @MsgbText = MSGB_TEXT ,
                @TempMsgbText = MSGB_TEXT ,
                @LineType = LINE_TYPE ,
                @InsrCnamStat = INSR_CNAM_STAT ,
                @ClubName = CLUB_NAME ,
                @Cel1Phon = CEL1_PHON ,
                @Cel2Phon = CEL2_PHON ,
                @Cel3Phon = CEL3_PHON ,
                @Cel4Phon = CEL4_PHON ,
                @Cel5Phon = CEL5_PHON
        FROM    dbo.Message_Broadcast
        WHERE   MSGB_TYPE = '030';                    
            
        SELECT  @AmntType = rg.AMNT_TYPE ,
                @AmntTypeDesc = d.DOMN_DESC
        FROM    iScsc.dbo.Regulation rg ,
                iScsc.dbo.[D$ATYP] d
        WHERE   rg.TYPE = '001'
                AND rg.REGL_STAT = '002'
                AND rg.AMNT_TYPE = d.VALU;

                    
        IF @MsgbStat = '002'
        BEGIN
            SELECT  @MsgbText = ( SELECT    N'حذف پرداختی مشترک' + CHAR(10)
                                            + N'از صورتحساب ' + rt.RQTP_DESC
                                            + N' ' + f.NAME_DNRM + N'مبلغ '
                                            + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, d.AMNT), 1),
                                                      '.00', '') + N' '
                                            + @AmntTypeDesc + N'حذف گردید'
                                            + CHAR(10) + N'کاربر : '
                                            + UPPER(SUSER_NAME()) + CHAR(10)
                                            + N'تاریخ : '
                                            + dbo.GET_MTOS_U(GETDATE())
                                  FROM      dbo.Request_Type rt ,
                                            dbo.Request r ,
                                            dbo.Request_Row rr ,
                                            dbo.Fighter f ,
                                            Deleted d
                                  WHERE     r.RQID = rr.RQST_RQID
                                            AND rr.FIGH_FILE_NO = f.FILE_NO
                                            AND r.RQID = d.PYMT_RQST_RQID
                                );          
            SELECT  @XMsg = ( SELECT    5 AS '@subsys' ,
                                        @LineType AS '@linetype' ,
                                        ( SELECT    @Cel1Phon AS '@phonnumb' ,
                                                    ( SELECT  '030' AS '@type' ,
                                                              @MsgbText
                                                    FOR
                                                      XML PATH('Message') ,
                                                          TYPE
                                                    )
                                        FOR
                                          XML PATH('Contact') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    @Cel2Phon AS '@phonnumb' ,
                                                    ( SELECT  '030' AS '@type' ,
                                                              @MsgbText
                                                    FOR
                                                      XML PATH('Message') ,
                                                          TYPE
                                                    )
                                        FOR
                                          XML PATH('Contact') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    @Cel3Phon AS '@phonnumb' ,
                                                    ( SELECT  '030' AS '@type' ,
                                                              @MsgbText
                                                    FOR
                                                      XML PATH('Message') ,
                                                          TYPE
                                                    )
                                        FOR
                                          XML PATH('Contact') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    @Cel4Phon AS '@phonnumb' ,
                                                    ( SELECT  '030' AS '@type' ,
                                                              @MsgbText
                                                    FOR
                                                      XML PATH('Message') ,
                                                          TYPE
                                                    )
                                        FOR
                                          XML PATH('Contact') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    @Cel5Phon AS '@phonnumb' ,
                                                    ( SELECT  '030' AS '@type' ,
              @MsgbText
                         FOR
                                                      XML PATH('Message') ,
                                                          TYPE
                                                    )
                                        FOR
                                          XML PATH('Contact') ,
                                              TYPE
                                        )
                            FOR
                              XML PATH('Contacts') ,
                                  ROOT('Process')
                            );
            EXEC dbo.MSG_SEND_P @X = @XMsg; -- xml                  
        END;       
                
    END;

END;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_PMTD]
   ON [dbo].[Payment_Method]
   AFTER INSERT
AS 
BEGIN   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- 1398/02/23 * بررسی اینکه کاربر اجازه ثبت وصولی نقدی را دارد یا خیر
   IF EXISTS(
      SELECT * 
        FROM Inserted i
       WHERE i.RCPT_MTOD = '001' -- نقدی
   )
   BEGIN
      -- چک کردن دسترسی کاربر
      DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>237</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 237 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END   
   END
   -- آیا کاربر اجازه ثبت وصولی در هر تاریخ دلخواهی دارد یا خیر
   IF EXISTS(
      SELECT * 
        FROM Inserted i
       WHERE CAST(i.ACTN_DATE AS DATE) != CAST(GETDATE() AS DATE) -- تاریخ امروز
   )
   BEGIN
      -- چک کردن دسترسی کاربر
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>239</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 239 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END   
   END
   
   
   DECLARE @TotlRcptAmnt BIGINT;
   DECLARE @TotlDebtAmnt BIGINT;
   DECLARE @TotlRemnAmnt BIGINT;
   
   SELECT @TotlRcptAmnt = 
          SUM(Amnt)
     FROM Payment_Method T
    WHERE EXISTS(
      SELECT *
        FROM INSERTED S
       WHERE S.PYMT_CASH_CODE = T.PYMT_CASH_CODE
         AND S.PYMT_RQST_RQID = T.PYMT_RQST_RQID
         AND T.RWNO           <> 0
    );
   
   SELECT @TotlDebtAmnt =
          SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT + T.SUM_REMN_PRIC
     FROM Payment T
    WHERE EXISTS(
      SELECT *
        FROM INSERTED S
       WHERE S.PYMT_CASH_CODE = T.CASH_CODE
         AND S.PYMT_RQST_RQID = T.RQST_RQID
    );
   
   SELECT @TotlRemnAmnt = SUM(AMNT)
     FROM INSERTED S;
   
   IF ISNULL(@TotlRemnAmnt, 0) + ISNULL(@TotlRcptAmnt, 0) > ISNULL(@TotlDebtAmnt, 0)
   BEGIN
      RAISERROR(N'مبلغ بدهی مشتری کمتر مبلغ وارد شده می باشد. لطفا مبلغ درست را وارد کنید.', 16, 1);
   END 
   
   IF EXISTS(SELECT * FROM INSERTED WHERE AMNT IS NULL)
      RAISERROR(N'مبلغ بدهی مشتری باید مبلغ قابل قبول و درستی باشد.', 16, 1);
   
   -- Insert statements for trigger here
   MERGE dbo.Payment_Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Payment_Method WHERE PYMT_CASH_CODE = S.PYMT_CASH_CODE AND PYMT_RQST_RQID = S.PYMT_RQST_RQID AND RQRO_RQST_RQID = S.RQRO_RQST_RQID AND RQRO_RWNO      = S.RQRO_RWNO)
            ,ACTN_DATE = COALESCE(S.Actn_Date, GETDATE())
            ,FIGH_FILE_NO_DNRM = (SELECT rr.FIGH_FILE_NO FROM dbo.Request_Row rr WHERE rr.RQST_RQID = S.RQRO_RQST_RQID AND rr.RWNO = s.RQRO_RWNO)
            ,T.VALD_TYPE = ISNULL(S.VALD_TYPE, '002');
   
   -- اگر مبلغ ذخیره شده صفر باشد   
   DELETE Payment_Method
    WHERE EXISTS(
      SELECT *
        FROM INSERTED S
       WHERE S.PYMT_CASH_CODE = Payment_Method.PYMT_CASH_CODE
         AND S.PYMT_RQST_RQID = Payment_Method.PYMT_RQST_RQID
         AND S.RQRO_RQST_RQID = Payment_Method.RQRO_RQST_RQID
         AND S.RQRO_RWNO      = Payment_Method.RQRO_RWNO
         AND S.AMNT           = Payment_Method.AMNT
         AND Payment_Method.AMNT = 0
    )
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PMTD]
   ON [dbo].[Payment_Method]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- اگر کاربری بخواهد مبلغ وصولی غیر نقدی را تبدیل به مبلغ وصولی نقدی کند باید چک کنیم که ایا اجازه این کار وجود دارد یا خیر
	IF EXISTS(
	   SELECT *
	     FROM Inserted i, Deleted d
	    WHERE i.PYMT_CASH_CODE = d.PYMT_CASH_CODE
	      AND i.PYMT_RQST_RQID = d.PYMT_RQST_RQID
	      AND i.RWNO = d.RWNO
	      AND d.RCPT_MTOD != '001' -- غیر نقدی
	      AND i.RCPT_MTOD = '001' -- نقدی
	)
	BEGIN
	   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>237</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 237 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
	END 
	-- آیا کاربر اجازه ثبت وصولی در هر تاریخ دلخواهی دارد یا خیر
   IF EXISTS(
      SELECT * 
        FROM Inserted i
       WHERE CAST(i.ACTN_DATE AS DATE) != CAST(GETDATE() AS DATE) -- تاریخ امروز
   )
   BEGIN
      -- چک کردن دسترسی کاربر
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>239</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 239 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END   
   END
   
   DECLARE @TotlRcptAmnt BIGINT;
   DECLARE @TotlDebtAmnt BIGINT;
   DECLARE @TotlRemnAmnt BIGINT;
   
   SELECT @TotlRcptAmnt = 
          SUM(Amnt)
     FROM Payment_Method T
    WHERE EXISTS(
      SELECT *
        FROM INSERTED S
       WHERE S.PYMT_CASH_CODE = T.PYMT_CASH_CODE
         AND S.PYMT_RQST_RQID = T.PYMT_RQST_RQID
         AND S.RWNO          <> T.RWNO
    );
   
   SELECT @TotlDebtAmnt =
          SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT + t.SUM_REMN_PRIC - T.SUM_PYMT_DSCN_DNRM
     FROM Payment T
    WHERE EXISTS(
      SELECT *
        FROM INSERTED S
       WHERE S.PYMT_CASH_CODE = T.CASH_CODE
         AND S.PYMT_RQST_RQID = T.RQST_RQID
    );
   
   SELECT @TotlRemnAmnt = SUM(AMNT)
     FROM INSERTED S;
   
   --PRINT @TotlRemnAmnt;
   --PRINT @TotlRcptAmnt;
   --PRINT @TotlDebtAmnt;
   IF ISNULL(@TotlRemnAmnt, 0) + ISNULL(@TotlRcptAmnt, 0) > ISNULL(@TotlDebtAmnt, 0)
   BEGIN
      RAISERROR(N'مبلغ بدهی مشتری کمتر از مبلغ وارد شده می باشد. لطفا مبلغ را اصلاح کنید.', 16, 1);
   END 
   
   -- بررسی اینکه اگر بخواهیم از سپرده مشتری استفاه کنیم ایا میزان مبلغ پرداختی به اندازه سپرده فعلی مشتری و همچنین کمتر باشد
   IF EXISTS(SELECT * FROM Inserted i, dbo.Fighter f WHERE i.FIGH_FILE_NO_DNRM = f.FILE_NO AND i.AMNT > f.DPST_AMNT_DNRM AND i.RCPT_MTOD = '005')
      RAISERROR(N'مبلغ وارد شده از مبلغ سپرده بیشتر می باشد. لطفا مبلغ را اصلاح کنید.', 16, 1);
   
   
   -- Insert statements for trigger here
   MERGE dbo.Payment_Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY   = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE()
            ,T.ACTN_DATE = CASE CAST(s.ACTN_DATE AS TIME(0)) WHEN '00:00:00' THEN s.ACTN_DATE + CAST(GETDATE() AS TIME(0)) ELSE s.ACTN_DATE END;
   
   -- 1395/12/27 * بروز رسانی جدول هزینه برای ستون جمع مبلغ های دریافتی مشترک
   MERGE dbo.Payment T
   USING (SELECT * FROM Inserted )S
   ON (T.CASH_CODE = S.PYMT_CASH_CODE AND 
       T.RQST_RQID = S.PYMT_RQST_RQID)
   WHEN MATCHED THEN
      UPDATE SET
         T.SUM_RCPT_EXPN_PRIC = (
            SELECT ISNULL(SUM(Amnt) , 0)
              FROM dbo.Payment_Method
             WHERE PYMT_CASH_CODE = S.PYMT_CASH_CODE
               AND PYMT_RQST_RQID = S.PYMT_RQST_RQID
         );
   
   
   -- بروز کردن مبلغ بدهی هنرجو
   UPDATE dbo.Fighter
      SET CONF_STAT = CONF_STAT
    WHERE FILE_NO IN (
      SELECT FIGH_FILE_NO
        FROM dbo.Request_Row Rr, INSERTED I
       WHERE Rr.Rqst_rqid = I.Pymt_Rqst_Rqid       
    );
END
;
GO
ALTER TABLE [dbo].[Payment_Method] ADD CONSTRAINT [PK_PMTD] PRIMARY KEY CLUSTERED  ([PYMT_CASH_CODE], [PYMT_RQST_RQID], [RQRO_RQST_RQID], [RQRO_RWNO], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Method] ADD CONSTRAINT [FK_PMMT_APBS] FOREIGN KEY ([RCPT_TO_OTHR_ACNT]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Payment_Method] ADD CONSTRAINT [FK_PMTD_FIGH] FOREIGN KEY ([FIGH_FILE_NO_DNRM]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Payment_Method] ADD CONSTRAINT [FK_PMTD_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Method] ADD CONSTRAINT [FK_PMTD_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ انجام', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'ACTN_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بانک صادر کننده', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'BANK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره کارت', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'CARD_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پیگیری', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'FLOW_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع پرداخت مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'RCPT_MTOD'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره ارجاع', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'REF_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شناسه فروشگاه / پذیرنده', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'SHOP_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره ترمینال', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'TERM_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره تراکنش', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'TRAN_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای این می باشد که ایا این پرداختی به عنوان درآمد محسوب میشود یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Method', 'COLUMN', N'VALD_TYPE'
GO
