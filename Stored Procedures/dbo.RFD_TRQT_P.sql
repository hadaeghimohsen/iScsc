SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RFD_TRQT_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>182</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 182 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   DECLARE @ErrorMessage NVARCHAR(MAX);
   BEGIN TRY
   BEGIN TRAN T1
   
	   DECLARE @Rqid     BIGINT
	          ,@RqstRqid BIGINT
	          ,@MdulName VARCHAR(11)
	          ,@SctnName VARCHAR(11)
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@FileNo   BIGINT
	          ,@RqroRwno SMALLINT;
  	   
  	   SELECT @RqtpCode = '019'
  	         ,@RqttCode = '004';
  	    
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END

      SELECT @RegnCode = Regn_Code, 
             @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;

      -- ثبت شماره درخواست 
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            NULL,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;  
            
         UPDATE Request
            SET MDUL_NAME = @MdulName
              ,SECT_NAME = @SctnName
          WHERE RQID = @Rqid;                
      END
      
      -- درخواست مرتبط برای استرداد وجه
      IF @RqstRqid > 0
      BEGIN
         DECLARE @RqstRqidRqtpCode VARCHAR(3)
                ,@RqstRqidRqttCode VARCHAR(3);
         -- بدست آوردن نوع درخواست استردادی
         SELECT @RqstRqidRqtpCode = RQTP_CODE
               ,@RqstRqidRqttCode = RQTT_CODE
           FROM dbo.Request
          WHERE RQID = @RqstRqid;
         
         IF EXISTS(
            SELECT * 
              FROM dbo.Request
             WHERE RQST_RQID = @RqstRqid
               AND RQTP_CODE = '019'
               AND RQST_STAT = '002'
         )
         BEGIN
            RAISERROR(N'درخواست انتخاب شده قبلا تسویه و استرداد وجه با آن صورت گرفته است!', 16, 1);
            RETURN;
         END
         
         IF @RqstRqidRqttCode IN ('004')
         BEGIN
            RAISERROR(N'درخواست انتخاب شده درخواست پیرو می باشد شما نمی توانید در فرآیند استرداد برگشت هزینه کنید!', 16, 1);
            RETURN;
         END
         
         IF @RqstRqidRqtpCode IN ('001')
         BEGIN
            IF NOT EXISTS(
               SELECT *
                 FROM Request_Row Rr,
                      dbo.Fighter F,
                      dbo.Member_Ship Ms
                WHERE Rr.FIGH_FILE_NO = F.FILE_NO
                  AND Rr.RQST_RQID = Ms.RQRO_RQST_RQID
                  AND Rr.RWNO = ms.RQRO_RWNO
                  AND ms.RECT_CODE = '004'
                  AND Rr.RQST_RQID = (SELECT Ri.Rqid FROM dbo.Request Ri WHERE Ri.RQST_RQID = @RqstRqid AND ri.RQTP_CODE = '009')
                  AND CONVERT(DATE,Ms.END_DATE) > CONVERT(DATE, GETDATE())
            )
            BEGIN
               RAISERROR(N'تاریخ ثبت نام این درخواست نامعتبر می باشد. شما قادر به استرداد وجه درخواست نیستید!', 16, 1);
               RETURN;
            END            
         END
         
         UPDATE dbo.Request
            SET RQST_RQID = @RqstRqid
          WHERE RQID = @Rqid;
      END
      
      -- ثبت ردیف درخواست 
      SELECT @RqroRwno = Rwno
        FROM Request_Row
       WHERE RQST_RQID = @Rqid
         AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
 	   
 	   IF @RqstRqid > 0
 	   BEGIN
 	      DECLARE @Rlid BIGINT
 	             ,@LettNo VARCHAR(20)
                ,@LettDate DATE
                ,@RqltDesc NVARCHAR(240);
                
 	      SELECT @LettNo   = @X.query('//Request_Letter').value('(Request_Letter/@lettno)[1]', 'VARCHAR(20)')
	            ,@LettDate = @X.query('//Request_Letter').value('(Request_Letter/@lettdate)[1]', 'DATE')
	            ,@RqltDesc = @X.query('//Request_Letter').value('(Request_Letter/@rqltdesc)[1]', 'NVARCHAR(240)');
	      
	      IF LEN(@LettNo) = 0
	         SET @LettNo = NULL;

	         
	      -- اگر شماره درخواست پیرو تغییر کرد
	      IF EXISTS(
	         SELECT *
	           FROM Request
	          WHERE RQID = @Rqid
	            AND RQST_RQID != @RqstRqid
	      )
	      BEGIN
	         DELETE dbo.Finance_Document
	           WHERE RQRO_RQST_RQID = @Rqid
	             AND RQRO_RWNO = @RqroRwno;
	         
	         DELETE dbo.Request_Letter
	          WHERE RQST_RQID = @Rqid;
	      END
	      
	      
	      IF NOT EXISTS(
	         SELECT *
	           FROM Request_Letter
	          WHERE RQST_RQID = @Rqid	           
	      )
	         INSERT INTO dbo.Request_Letter
	                 ( RLID,
	                   RWNO,
	                   RQST_RQID ,
	                   REC_STAT ,
	                   LETT_NO ,
	                   LETT_DATE ,
	                   LETT_TYPE ,
	                   RQLT_DESC 
	                 )
	         VALUES  ( 0,
	                   0,
	                   @Rqid , -- RQST_RQID - bigint
	                   '001' , -- REC_STAT - varchar(3)
	                   ISNULL(@Lettno, REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', '')) , -- LETT_NO - varchar(20)
	                   CASE @LettDate WHEN '1900-01-01' THEN GETDATE() ELSE @LettDate END , -- LETT_DATE - date
	                   '001' , -- LETT_TYPE - varchar(3)
	                   @RqltDesc  -- RQLT_DESC - nvarchar(240)
	                 );
	      ELSE
	         UPDATE dbo.Request_Letter
	            SET LETT_NO = @LettNo
	               ,LETT_DATE = @LettDate
	               ,RQLT_DESC = @RqltDesc
	          WHERE RQST_RQID = @Rqid;
	      
	      -- بدست آوردن شماره نامه
	      SELECT @Rlid = RLID
	        FROM dbo.Request_Letter
	       WHERE RQST_RQID = @Rqid;    
	      
	      DECLARE @DcmtNo VARCHAR(20)
	             ,@DcmtDate DATE
	             ,@DcmtPric BIGINT
	             ,@DcmtDesc NVARCHAR(500)
	             ,@DcmtPricType VARCHAR(3)
	             ,@DebtDnrm BIGINT
	             ,@PymtPricDnrm BIGINT;
	      
	      SELECT @DcmtNo       = @X.query('//Finance_Document').value('(Finance_Document/@dcmtno)[1]', 'VARCHAR(20)')
	            ,@DcmtDate     = @X.query('//Finance_Document').value('(Finance_Document/@dcmtdate)[1]', 'DATE')
	            ,@DcmtPric     = @X.query('//Finance_Document').value('(Finance_Document/@dcmtpric)[1]', 'BIGINT')	            
	            ,@DcmtDesc     = @X.query('//Finance_Document').value('(Finance_Document/@dcmtdesc)[1]', 'NVARCHAR(500)')
	            ,@DcmtPricType = @X.query('//Finance_Document').value('(Finance_Document/@dcmtprictype)[1]', 'VARCHAR(3)');
	      
	      SELECT @DebtDnrm = DEBT_DNRM
	            ,@PymtPricDnrm = PYMT_PRIC_DNRM
	        FROM dbo.Finance_Document
	       WHERE RQRO_RQST_RQID = @Rqid
	         AND RQRO_RWNO = @RqroRwno
	         AND RQLT_RLID = @Rlid;
	      
	      IF LEN(@DcmtPricType) = 0
	         SET @DcmtPricType = '001';
	         
	      IF @DcmtPric IS NULL OR @DcmtPric = 0
	         SET @DcmtPric = @PymtPricDnrm - @DebtDnrm
	      ELSE IF @DcmtPric > @PymtPricDnrm - @DebtDnrm
	      BEGIN
	         RAISERROR (N'مبلغ استردادوجه نمی تواند از میزان مبلغ پرداخت بیشتر باشد', 16, 1);
	         RETURN;
	      END
	      ELSE IF @DcmtPric <= @DebtDnrm
	      BEGIN
	         RAISERROR (N'مبلغ استردادوجه نمی تواند از میزان بدهی بیشتر یا مساوی باشد', 16, 1);
	         RETURN;
	      END	      
	      
	      IF NOT EXISTS
	      (
	         SELECT *
	           FROM dbo.Finance_Document
	          WHERE RQRO_RQST_RQID = @Rqid
	            AND RQRO_RWNO = @RqroRwno
	            AND RQLT_RLID = @Rlid 
	            AND REC_STAT = '001'
	      )
	      BEGIN
	         INSERT INTO dbo.Finance_Document
	              ( FDID,
	                RWNO,
	                RQRO_RQST_RQID ,
	                RQRO_RWNO ,
	                RQLT_RLID ,
	                REC_STAT ,
	                DCMT_NO ,
	                DCMT_DATE ,	                
	                DCMT_DESC,
	                --PYMT_PRIC_DNRM,
	                DCMT_PRIC_TYPE
	              )
	         VALUES(0,
	                0,
	                @Rqid , -- RQRO_RQST_RQID - bigint
	                @RqroRwno , -- RQRO_RWNO - smallint
	                @Rlid , -- RQLT_RLID - bigint
	                '001' , -- REC_STAT - varchar(3)
	                dbo.GET_MTOS_U(GETDATE()) , -- DCMT_NO - varchar(20)
	                GETDATE() , -- DCMT_DATE - date	                
	                @DcmtDesc,
	                /*(
	                  SELECT SUM_RCPT_EXPN_PRIC + ISNULL(SUM_RCPT_EXPN_EXTR_PRCT, 0) + ISNULL(SUM_RCPT_REMN_PRIC, 0) 
	                    FROM Payment P 
	                   WHERE P.RQST_RQID = @RqstRqid
	                ),*/
	                @DcmtPricType
	              );
	         UPDATE dbo.Finance_Document
	            SET DCMT_PRIC = PYMT_PRIC_DNRM - DEBT_DNRM
	          WHERE RQRO_RQST_RQID = @Rqid
	            AND RQRO_RWNO = @RqroRwno
	            AND RQLT_RLID = @Rlid
	            AND REC_STAT = '001';
	      END
	      ELSE
	         UPDATE dbo.Finance_Document
	            SET DCMT_NO   = @DcmtNo
	               ,DCMT_DATE = @DcmtDate
	               ,DCMT_PRIC = @DcmtPric
	               ,DCMT_DESC = @DcmtDesc
	               ,DCMT_PRIC_TYPE = @DcmtPricType
	          WHERE RQRO_RQST_RQID = @Rqid
	            AND RQRO_RWNO = @RqroRwno
	            AND RQLT_RLID = @Rlid
	            AND REC_STAT = '001';
	      
	      DECLARE C$RFPD CURSOR FOR
	         SELECT r.query('.').value('(Refunds_Payment_Detail/@rfid)[1]', 'BIGINT')
	               ,r.query('.').value('(Refunds_Payment_Detail/@rfndstat)[1]', 'VARCHAR(3)')
	           FROM @x.nodes('//Refunds_Payment_Detail') T(r);
	      
	      DECLARE @Rfid BIGINT,
	              @RfndStat VARCHAR(3);
	      
	      OPEN C$RFPD;
	      Fetch_C$RFPD:
	      FETCH NEXT FROM C$RFPD INTO @Rfid, @RfndStat;
	      
	      IF @@FETCH_STATUS <> 0
	         GOTO End_C$RFPD;
	      
	      UPDATE dbo.Refunds_Payment_Detail
	         SET RFND_STAT = @RfndStat
	      WHERE RFID = @Rfid;	      
	      
	      GOTO Fetch_C$RFPD;
	      End_C$RFPD:
	      CLOSE C$RFPD;
	      DEALLOCATE C$RFPD;	      
	               
      END
      COMMIT TRAN T1
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;   
   END CATCH
END
GO
