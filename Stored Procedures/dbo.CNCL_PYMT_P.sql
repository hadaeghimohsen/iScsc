SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CNCL_PYMT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$CNCL_PYMT_P]
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>243</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 243 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   DECLARE @Rqid BIGINT
          ,@RqstRqid BIGINT
          ,@OrginRqid BIGINT
          ,@PrvnCode VARCHAR(3)
          ,@RegnCode VARCHAR(3)
          ,@CnclType VARCHAR(3);
          
	SELECT @RqstRqid = @x.query('Payment').value('(Payment/@rqid)[1]', 'BIGINT'),
	       @CnclType = @x.query('Payment').value('(Payment/@cncltype)[1]', 'VARCHAR(3)');	
	
	IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTT_CODE = '001' AND RQTP_CODE = '001')
	   SELECT @RqstRqid = RQST_RQID
	     FROM dbo.Request
	    WHERE RQID = @RqstRqid;
	
	SET @OrginRqid = @RqstRqid;
	
	-- بررسی اینکه صورتحساب قبلا ابطال نشده باشد
	IF EXISTS (SELECT * FROM dbo.Payment WHERE RQST_RQID = @RqstRqid AND PYMT_STAT = '002')
	BEGIN
	   RAISERROR ( N'صورتحساب قبلا ابطال شده است', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
	END;
	
	SELECT @PrvnCode = REGN_PRVN_CODE
	      ,@RegnCode = REGN_CODE
	  FROM dbo.Request
	 WHERE RQID = @RqstRqid;
	
	DECLARE @RqtpCode VARCHAR(3) = CASE @CnclType WHEN '001' THEN '029' WHEN '002' THEN '030' END;
	
	-- ثبت شماره درخواست 
   IF @Rqid IS NULL OR @Rqid = 0
   BEGIN
      EXEC dbo.INS_RQST_P
         @PrvnCode,
         @RegnCode,
         NULL,
         @RqtpCode,
         '004',
         NULL,
         NULL,
         NULL,
         @Rqid OUT;
   END
   ELSE
   BEGIN
      EXEC UPD_RQST_P
         @Rqid,
         @PrvnCode,
         @RegnCode,
         @RqtpCode,
         '004',
         NULL,
         NULL,
         NULL;            
   END
	
	-- بدست آوردن شماره پرونده مشتری
   DECLARE @FileNo BIGINT;
   SELECT @FileNo = FIGH_FILE_NO
     FROM dbo.Request_Row
    WHERE RQST_RQID = @RqstRqid;
    
   -- ثبت ردیف درخواست 
   DECLARE @RqroRwno SMALLINT;
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
	
	-- ایا درخواست ثبت نام یا تمدید میباشد
	IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTP_CODE IN ('001', '009'))
	BEGIN 
	   -- پیدا کردن درخواست مربوط به جدول دوره متصل 	   
	   IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTP_CODE = '001' AND RQTP_CODE != '001')
	      SELECT @RqstRqid = RQID
	        FROM dbo.Request
	       WHERE RQST_RQID = @RqstRqid
	         AND RQTP_CODE = '009';
      
      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTP_CODE = '001' AND RQTT_CODE = '001')
      BEGIN
         -- غیرفعال کردن دوره 
         UPDATE dbo.Member_Ship
            SET VALD_TYPE = '001'
          WHERE RQRO_RQST_RQID = (SELECT RQID FROM dbo.Request WHERE RQST_RQID = @RqstRqid AND RQST_STAT = '002' AND RQTT_CODE = '004')
            AND RECT_CODE = '004';
      END
      ELSE
      BEGIN      
         -- غیرفعال کردن دوره 
         UPDATE dbo.Member_Ship
            SET VALD_TYPE = '001'
          WHERE RQRO_RQST_RQID = @RqstRqid
            AND RECT_CODE = '004';
      END;
   END
   
   -- اگر صورتحساب مشتری دارای پرداختی میباشد مبلغ پرداختی را به صورت سپرده قرار میدهیم
   IF EXISTS(SELECT * FROM dbo.Payment_Method WHERE PYMT_RQST_RQID = @RqstRqid)
   BEGIN
      DECLARE @Amnt BIGINT;
      SELECT @Amnt = SUM(AMNT)
        FROM dbo.Payment_Method
       WHERE RQRO_RQST_RQID = @OrginRqid;
       
      SELECT @x = (
         SELECT 
            0 AS '@rqid',
            @Rqid AS '@rqstrqid',
            @FileNo AS 'Request_Row/@fighfileno',
            0 AS 'Gain_Loss_Rials/@glid',
            '002' AS 'Gain_Loss_Rials/@type',
            @Amnt AS 'Gain_Loss_Rials/@amnt',
            GETDATE() AS 'Gain_Loss_Rials/@paiddate',
            '002' AS 'Gain_Loss_Rials/@dpststat',
            N'افزایش سپرده بابت ابطال صورتحساب',
            (
               SELECT 1 AS '@rwno',
                      @Amnt AS '@amnt',
                      '012' AS '@rcptmtod'
                 --FROM dbo.Payment_Method
                --WHERE PYMT_RQST_RQID = @OrginRqid
                  FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
            )
            FOR XML PATH('Request'), ROOT('Process')
      );
      
      EXEC dbo.GLR_TRQT_P @X = @X -- xml
      
      SELECT @RqstRqid = RQID
        FROM dbo.Request
       WHERE RQTP_CODE = '020'
         AND RQST_STAT = '001'
         AND RQTT_CODE = '004'
         AND CRET_BY = UPPER(SUSER_NAME())
         AND SUB_SYS = 1;
      
      SELECT @X = (
         SELECT @RqstRqid AS '@rqid'
            FOR XML PATH('Request'), ROOT('Process')
      );
      
      EXEC dbo.GLR_TSAV_P @X = @X -- xml      
   END 
   
   SET @RqstRqid = NULL;
   
      -- تغییر وضعیت صورتحساب به حالت ابطال
   UPDATE dbo.Payment 
      SET PYMT_STAT = '002' -- وضعیت صورتحساب به صورت ابطال در اورده میشود
    WHERE RQST_RQID = @OrginRqid;
   
   -- پایان درخواست
   UPDATE Request
      SET RQST_STAT = '002'
         ,RQST_RQID = @OrginRqid
    WHERE RQID = @Rqid;
   
   -- 001 درخواست ابطال عادی
   -- 002 درخواست صدور صورتحساب اصلاحی
   IF @CnclType = '002' 
   BEGIN
      -- اگر درخواست اصلاح صورتحساب متعلق به ثبت نام و تمدید باشد
      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE IN ('001', '009'))
      BEGIN
         SET @RqstRqid = @OrginRqid;
         -- پیدا کردن درخواست مربوط به جدول دوره متصل 	   
	      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE = '001' AND RQTP_CODE = '001')
	         SELECT @RqstRqid = RQID
	           FROM dbo.Request
	          WHERE RQST_RQID = @OrginRqid
	            AND RQTP_CODE = '009';
	       
         SELECT @X = (
            SELECT 0 AS '@rqid'
                  ,@Rqid AS '@rqstrqid'
                  ,'009' AS '@rqtpcode'
                  ,'001' AS '@rqttcode'                  
                  ,(
                     SELECT @FileNo AS '@fileno'
                           ,STRT_DATE AS 'Member_Ship/@strtdate'
                           ,END_DATE AS 'Member_Ship/@enddate'
                           ,PRNT_CONT AS 'Member_Ship/@prntcont'
                           ,NUMB_MONT_OFER AS 'Member_Ship/@numbmontofer'
                           ,NUMB_OF_ATTN_MONT AS 'Member_Ship/@numbofattnmont'
                           ,NUMB_OF_ATTN_WEEK AS 'Member_Ship/@numbofattnweek'
                           ,'' AS 'Member_Ship/@newfngrprnt'
                       FROM dbo.Member_Ship
                      WHERE RQRO_RQST_RQID = @RqstRqid
                        AND RECT_CODE = '004'
                        FOR XML PATH('Request_Row'), TYPE
                  )
              FOR XML PATH('Request'), ROOT('Process')
         );
         
         EXEC dbo.UCC_TRQT_P @X = @X -- xml         
         
         SELECT @RqstRqid = RQID
           FROM dbo.Request
          WHERE RQTP_CODE = '009'
            AND RQST_STAT = '001'
            AND RQTT_CODE = '004'
            AND CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;
      END
      /*ELSE IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE = '016')
      BEGIN
         SELECT 'Fuck :|';
      END */
   END 
	
	COMMIT TRANSACTION [T$CNCL_PYMT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$CNCL_PYMT_P]
	END CATCH
END
GO
