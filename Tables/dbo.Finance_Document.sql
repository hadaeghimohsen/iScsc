CREATE TABLE [dbo].[Finance_Document]
(
[FDID] [bigint] NOT NULL,
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[RQLT_RLID] [bigint] NULL,
[RWNO] [smallint] NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__Finance_D__REC_S__21E0EDE6] DEFAULT ('002'),
[DEBT_DNRM] [bigint] NULL,
[PYMT_PRIC_DNRM] [bigint] NULL,
[GET_PYMT_PRIC_DNRM] [bigint] NULL,
[REGL_YEAR_DNRM] [smallint] NULL,
[REGL_CODE_DNRM] [int] NULL,
[DCMT_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DCMT_DATE] [date] NULL,
[DCMT_PRIC] [bigint] NULL,
[DCMT_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DCMT_PRIC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Finance_Document_DCMT_PRIC_TYPE] DEFAULT ('001'),
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
CREATE TRIGGER [dbo].[CG$AINS_FIDC]
   ON  [dbo].[Finance_Document]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DECLARE @Fdid BIGINT;
   SET @Fdid = dbo.GNRT_NVID_U();
   
   -- Insert statements for trigger here
   MERGE dbo.[Finance_Document] T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RQLT_RLID      = S.RQLT_RLID      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY        = UPPER(SUSER_NAME())
            ,CRET_DATE      = GETDATE()
            ,FDID           = @Fdid;
   
   -- ثبت رکورد های هزینه از جدول 
   -- Payment_Detail
   -- به جدول 
   -- Refunds_Payment_Detail
   DECLARE @Rqid BIGINT,
           @FileNo BIGINT,
           @RqroRwno SMALLINT;
   
   SELECT @Rqid = R.RQST_RQID,
          @FileNo = Rr.FIGH_FILE_NO,
          @RqroRwno = Rr.RWNO
     FROM dbo.Request R, dbo.Request_Row Rr, INSERTED I
    WHERE R.RQID = Rr.RQST_RQID
      AND Rr.RQST_RQID = I.Rqro_Rqst_Rqid
      AND Rr.RWNO = I.Rqro_Rwno
      AND Rr.RECD_STAT = '002';      
   
   INSERT INTO dbo.Refunds_Payment_Detail
           ( FIDC_FDID ,
             PYDT_CODE ,
             PYDT_EXPN_CODE ,
             RFID ,
             RFND_STAT ,
             PYDT_PAY_STAT ,
             PYDT_EXPN_PRIC ,
             PYDT_EXPN_EXTR_PRCT ,
             PYDT_REMN_PRIC ,
             PYDT_QNTY ,
             PYDT_DOCM_NUMB ,
             PYDT_ISSU_DATE ,
             PYDT_RCPT_MTOD ,
             PYDT_RECV_LETT_NO ,
             PYDT_RECV_LETT_DATE ,
             PYDT_DESC 
           )
   SELECT @Fdid, CODE, EXPN_CODE, dbo.GNRT_NVID_U(), '001',
          PAY_STAT, EXPN_PRIC, EXPN_EXTR_PRCT, REMN_PRIC,
          QNTY, DOCM_NUMB, ISSU_DATE, RCPT_MTOD, RECV_LETT_NO,
          RECV_LETT_DATE, PYDT_DESC          
     FROM dbo.Payment_Detail
    WHERE PYMT_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno;
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_FIDC]
   ON  [dbo].[Finance_Document]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   DECLARE @FileNo BIGINT;
   
   -- Insert statements for trigger here
   MERGE dbo.[Finance_Document] T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RQLT_RLID      = S.RQLT_RLID      AND
       T.RWNO           = S.RWNO           AND
       T.FDID           = S.FDID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY        = UPPER(SUSER_NAME())
            ,MDFY_DATE      = GETDATE()
            ,REGL_YEAR_DNRM = (SELECT YEAR FROM Regulation WHERE SUB_SYS = 1 AND [TYPE] = '001' AND REGL_STAT = '002')
            ,REGL_CODE_DNRM = (SELECT CODE FROM Regulation WHERE SUB_SYS = 1 AND [TYPE] = '001' AND REGL_STAT = '002')
            ,DEBT_DNRM      = (SELECT DEBT_DNRM FROM Fighter WHERE RQST_RQID = T.RQRO_RQST_RQID)
            --,PYMT_PRIC_DNRM = (SELECT SUM_RCPT_EXPN_PRIC + ISNULL(SUM_RCPT_EXPN_EXTR_PRCT, 0) + ISNULL(SUM_RCPT_REMN_PRIC, 0) FROM Payment P WHERE P.RQST_RQID = (SELECT RQST_RQID FROM Request WHERE RQID = T.RQRO_RQST_RQID))
            --,DCMT_PRIC      = CASE WHEN S.DCMT_PRIC IS NULL THEN (SELECT SUM_RCPT_EXPN_PRIC + ISNULL(SUM_RCPT_EXPN_EXTR_PRCT, 0) + ISNULL(SUM_RCPT_REMN_PRIC, 0) FROM Payment P WHERE P.RQST_RQID = (SELECT RQST_RQID FROM Request WHERE RQID = T.RQRO_RQST_RQID)) - (SELECT DEBT_DNRM FROM Fighter WHERE RQST_RQID = T.RQRO_RQST_RQID) ELSE S.DCMT_PRIC END
            /*,DCMT_DESC      = CASE WHEN S.DCMT_DESC IS NULL THEN (SELECT N'استرداد وجه ' + (P.SUM_RCPT_EXPN_PRIC + ISNULL(P.SUM_RCPT_EXPN_EXTR_PRCT, 0) + ISNULL(P.SUM_RCPT_REMN_PRIC, 0)) + N' ریال بابت درخواست' + Rt.RQTP_DESC + N' به ' + CASE F.SEX_TYPE_DNRM WHEN '001' THEN N' آقای ' ELSE N' سرکارخانم ' END + F.NAME_DNRM + N' برگشت داده شد!'
                                                                    FROM Request_Type Rt, Request R, Request_Row Rr, Fighter F, Payment P
                                                                   WHERE Rt.CODE = R.RQTP_CODE
                                                                     AND R.RQID = RR.RQST_RQID      
                                                                     AND Rr.FIGH_FILE_NO = F.FILE_NO
                                                                     AND R.RQID = P.RQST_RQID 
                                                                     AND R.RQID = (SELECT A.RQST_RQID FROM Request A WHERE A.RQID = T.Rqro_Rqst_Rqid)) ELSE S.DCMT_DESC END*/;
   
	IF EXISTS( SELECT * FROM INSERTED I WHERE I.REC_STAT = '002' AND DCMT_PRIC_TYPE = '001' )
	BEGIN
	   DECLARE @Rwno BIGINT
	          ,@AcntRwno INT
	          ,@ActnDate DATETIME
	          ,@RegnPrvnCntyCode VARCHAR(3)
	          ,@RegnPrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@ClubCode BIGINT
	          ,@ExpnAmnt BIGINT
	          ,@Rqid BIGINT;
	   
	   SELECT @RegnPrvnCntyCode = F.REGN_PRVN_CNTY_CODE
	         ,@RegnPrvnCode = F.REGN_PRVN_CODE
	         ,@RegnCode = F.REGN_CODE
	         ,@ClubCode = CLUB_CODE_DNRM
	         ,@ExpnAmnt = I.DCMT_PRIC
	         ,@Rqid = F.RQST_RQID	         
	         ,@FileNo = F.FILE_NO
	     FROM dbo.Request_Row Rr, Fighter F, Inserted I
	    WHERE Rr.RQST_RQID = I.RQRO_RQST_RQID
	      AND Rr.RWNO = I.RQRO_RWNO
	      AND Rr.FIGH_FILE_NO = F.FILE_NO;

	   SET @ActnDate = GETDATE();
	   EXEC dbo.INS_ACTN_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, 0, '001', @ActnDate, @Rwno OUT;
	   EXEC dbo.INS_ACDT_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, @Rwno, @ExpnAmnt, '001', @ActnDate, NULL, @Rqid, NULL, @AcntRwno OUT;
	END
   ELSE IF EXISTS(SELECT * FROM INSERTED I WHERE I.REC_STAT = '002' AND DCMT_PRIC_TYPE = '002')
   BEGIN
      DECLARE @Amnt INT,
              @AgreDate DATETIME,
              @PaidDate DATETIME,
              @ResnDesc NVARCHAR(250),
              @Glid BIGINT;
      
      SELECT @Rqid = I.RQRO_RQST_RQID
            ,@Rwno = I.RQRO_RWNO
            ,@FileNo = Rr.FIGH_FILE_NO
            ,@Amnt = I.DCMT_PRIC + F.DEBT_DNRM
            ,@AgreDate = I.DCMT_DATE
            ,@PaidDate = I.DCMT_DATE
	     FROM Request_Row Rr, Inserted I, dbo.Fighter f
	    WHERE Rr.RQST_RQID = I.Rqro_Rqst_Rqid
	      AND Rr.RWNO = I.Rqro_Rwno
	      AND rr.FIGH_FILE_NO = f.FILE_NO;	    
      
      EXEC dbo.INS_GLRL_P @RqroRqstRqid = @Rqid, @RqroRwno = @Rwno, @FighFileNo = @FileNo, @ConfStat = '002', @ChngType = '002', @DebtType = '003', @Amnt = @Amnt, @AgreDate = @AgreDate, @PaidDate = @PaidDate, @ChngResn = '005', @ResnDesc = N'برگشت هزینه به صورت اتوماتیک پیرو درخواست', @Glid = @Glid OUT;                   
   END
   
   -- تغییرات بعد از استرداد هزینه هنرجو
   IF EXISTS(SELECT * FROM INSERTED I WHERE I.REC_STAT = '002')
   BEGIN
      DECLARE @RqtpCode VARCHAR(3)
             ,@X XML;
      
      SELECT @RqtpCode = (SELECT Ri.RQTP_CODE FROM dbo.Request Ri WHERE Ri.Rqid = R.RQST_RQID)
            ,@RegnCode = R.Regn_Code
            ,@RegnPrvnCode = R.Regn_Prvn_Code
            ,@Rqid = R.RQID
        FROM Request R, INSERTED I
       WHERE R.RQID = I.RQRO_RQST_RQID
         AND I.REC_STAT = '002';
      
      IF @RqtpCode IN ('001', '009')
      BEGIN
         DECLARE @CnclDate DATETIME;
         SET @CnclDate = DATEADD(DAY, -1, GETDATE());
         SET @X = '<Process><Request rqstrqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1"/></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@RegnPrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@CnclDate")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@CnclDate")');
         EXEC UCC_RQST_P @X;
         
         SELECT @Rqid = R.RQID
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '009'
            AND R.RQTT_CODE = '004';

         SET @X = '<Process><Request rqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row rwno="1" fileno=""><Member_Ship strtdate="" enddate="" prntcont="1"/></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@RegnPrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@CnclDate")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@CnclDate")');
         EXEC UCC_SAVE_P @X;
      END 
   END
END
;
GO
ALTER TABLE [dbo].[Finance_Document] ADD CONSTRAINT [PK_FIDC] PRIMARY KEY CLUSTERED  ([FDID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Finance_Document] ADD CONSTRAINT [FK_FIDC_REGL] FOREIGN KEY ([REGL_YEAR_DNRM], [REGL_CODE_DNRM]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE])
GO
ALTER TABLE [dbo].[Finance_Document] ADD CONSTRAINT [FK_FIDC_RQLT] FOREIGN KEY ([RQLT_RLID]) REFERENCES [dbo].[Request_Letter] ([RLID])
GO
ALTER TABLE [dbo].[Finance_Document] ADD CONSTRAINT [FK_FIDC_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
