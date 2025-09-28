SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[LNK_CRDO_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY 
	BEGIN TRAN [T$LNK_CRDO_P]
	   -- Local Params
	   DECLARE @OprtType varchar(3),
	           @FngrPrnt VARCHAR(20),
	           @CardFngrPrnt VARCHAR(20),
	           @CardFileNo BIGINT,
	           @Rqid BIGINT;	           
	   
	   -- Local Vars
	   DECLARE @AttnCode BIGINT,
	           @Code BIGINT,
	           @FineStat VARCHAR(3),
	           @FineAmntDnrm BIGINT,
	           @EdevCode BIGINT,
	           @ExpnCode BIGINT,
	           @Cmnt NVARCHAR(500),
	           @AtypDesc NVARCHAR(200);
	   
	   SELECT @OprtType = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@oprttype)[1]', 'VARCHAR(3)');
	   
	   IF @OprtType = '001'
	   BEGIN
	      -- مشتریان اشتراکی
	      SELECT @FngrPrnt = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@fngrprnt)[1]', 'VARCHAR(20)'),
	             @CardFngrPrnt = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfngrprnt)[1]', 'VARCHAR(20)'),
	             @CardFileNo = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfileno)[1]', 'BIGINT');
	      
	      -- پیدا کردن حضوری مشتری اشتراکی و ایجاد ارتباط با کارت زده شده
	      SELECT TOP 1 
	             @AttnCode = a.CODE
	        FROM dbo.Attendance a
	       WHERE a.FNGR_PRNT_DNRM = @FngrPrnt
	         AND a.ATTN_STAT = '002'
	         AND a.EXIT_TIME IS NULL
	         AND a.ATTN_DATE = CAST(GETDATE() AS DATE)
	         AND NOT EXISTS (
	                 SELECT *
	                   FROM dbo.Card_Link_Operation c
	                  WHERE c.ATTN_CODE = a.CODE	                    
	             );
	      
	      -- اگر حضوری آزاد برای مشتری اشتراکی وجود داشته باشد باید ارتباطات رو ایجاد کنیم
	      IF @AttnCode IS NOT NULL
	      BEGIN
	         -- ذخیره کردن کارت و کد حضور و غیاب مشتری
	         INSERT INTO dbo.Card_Link_Operation ( CARD_FILE_NO ,ATTN_CODE ,CODE )
            VALUES (@CardFileNo, @AttnCode, 0);	      
         END
	   END 
	   ELSE IF @OprtType = '002'
	   BEGIN
	      -- مشتریان مهمان
	      SELECT @Rqid = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@rqid)[1]', 'BIGINT'),
	             @CardFngrPrnt = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfngrprnt)[1]', 'VARCHAR(20)'),
	             @CardFileNo = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfileno)[1]', 'BIGINT');
	      
	      INSERT INTO dbo.Card_Link_Operation ( CARD_FILE_NO ,RQST_RQID ,CODE )
	      SELECT TOP 1
	             @CardFileNo, @Rqid, 0
	        FROM dbo.Request r
	       WHERE r.RQID = @Rqid
	         AND NOT EXISTS (
	             SELECT *
	               FROM dbo.Card_Link_Operation c
	              WHERE c.CARD_FILE_NO = @CardFileNo
	                AND c.RQST_RQID = r.RQID
	         );
	      
	   END
	   ELSE IF @OprtType = '003'
	   BEGIN
	      -- ذخیره و اتمام پایان بازی و ثبت جریمه در صورت لحاظ شدن
	      SELECT @CardFngrPrnt = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfngrprnt)[1]', 'VARCHAR(20)'),
	             @CardFileNo = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@cardfileno)[1]', 'BIGINT'),
	             @EdevCode = @X.query('//Card_Link_Operation').value('(Card_Link_Operation/@edevcode)[1]', 'BIGINT');
	      
	      -- بدست آوردن نوع واحد مالی
	      SELECT @AtypDesc = da.DOMN_DESC
	        FROM dbo.Regulation r, dbo.[D$ATYP] da
	       WHERE r.AMNT_TYPE = da.VALU;
	      
	      SELECT TOP 1
	             @Code = c.CODE
	        FROM dbo.Card_Link_Operation c
	       WHERE c.CARD_FILE_NO = @CardFileNo
	         AND c.END_TIME IS NULL
	         AND c.VALD_TYPE = '002';
	      
	      UPDATE dbo.Card_Link_Operation
	         SET END_TIME = GETDATE(),
	             EDEV_CODE = @EdevCode
	       WHERE CARD_FILE_NO = @CardFileNo
	         AND VALD_TYPE = '002'
	         AND END_TIME IS NULL;
	      
	      SELECT @FineStat = c.FINE_STAT
	             --@FineAmntDnrm = c.FINE_AMNT_DNRM
	             --@EdevCode = c.EDEV_CODE	             
	        FROM dbo.Card_Link_Operation c
	       WHERE c.CODE = @Code;
	      
	      IF @FineStat = '002'
	      BEGIN
	         -- پیدا کردن آیتم هزینه جریمه برای درخواست درامد متفرقه
	         SELECT @ExpnCode = EXPN_CODE
	           FROM dbo.External_Device 
	          WHERE CODE = @EdevCode;
	         
	         -- Checked Service IS LOCKED
	         SELECT @Rqid = f.RQST_RQID
	           FROM dbo.Fighter f
	          WHERE f.FILE_NO = @CardFileNo
	            AND f.FIGH_STAT = '001';
	         
	         IF @Rqid IS NOT NULL
	         BEGIN
	            -- باید درخواست موجود روی کارت رو برداشت
	            SET @X = (SELECT @Rqid AS '@rqid' FOR XML PATH('Request') );
	            EXEC dbo.CNCL_RQST_F @X = @X;	            
	         END;
	         
	         -- ابتدا باید شرح جریمه را مشخص کنیم
	         SET @Cmnt = (
	             SELECT CASE f.FGPB_TYPE_DNRM 
	                       WHEN '001' THEN N'صورتحساب جریمه ' + ds.DOMN_DESC + N' ' + 
	                                       f.LAST_NAME_DNRM + N' به شماره موبایل ' + f.CELL_PHON_DNRM + N' '
	                       WHEN '005' THEN N'صورتحساب جریمه برای مشتری مهمان آزاد '
	                    END +
	                    N'به دلیل تخلف بیش از حد زمان مبلغ ' + dbo.GET_NTOF_U(c.EXPN_1MIN_AMNT_DNRM * c.FINE_MINT_DNRM) + N' ' + @AtypDesc + N' شده اند' + CHAR(10) +
	                    N'زمان مجاز ' + CAST(c.TOTL_USE_MINT_DNRM AS VARCHAR(10)) + N' دقیقه' + CHAR(10) +	                    
	                    N'زمان شروع ' + dbo.GET_TIME_U(c.STRT_TIME) + CHAR(10) + 
	                    N'زمان پایان ' + dbo.GET_TIME_U(c.END_TIME) + CHAR(10) + 
	                    N'مدت زمان جریمه ' + CAST(c.FINE_MINT_DNRM AS VARCHAR(10)) + N' دقیقه' + CHAR(10)
	               FROM dbo.Card_Link_Operation c, dbo.Fighter f, dbo.[D$SXDC] ds
	              WHERE c.CODE = @Code
	                AND c.FIGH_FNGR_PRNT_DNRM = f.FNGR_PRNT_DNRM
	                AND f.SEX_TYPE_DNRM = ds.VALU
	         );
	         
	         -- حالا باید درخواست درامد متفرقه برای ثبت جریمه را انجام داد
            SELECT  @X = ( SELECT 0 AS '@rqid' ,
                                  '016' AS '@rqtpcode' ,
                                  '001' AS '@rqttcode' ,
                                  'OIC_TOTL_F' AS '@mdulname',
                                  'OIC_001_F' AS '@sctnname',
                                  @Cmnt AS '@rqstdesc',                                   
                                  ( SELECT    @CardFileNo AS '@fileno'
                                       FOR
                                       XML PATH('Request_Row') ,
                                      TYPE )
                              FOR XML PATH('Request'), ROOT('Process'), TYPE
             );
   
            EXEC dbo.OIC_ERQT_F @X = @X; -- xml
   
            SELECT  @Rqid = R.RQID
            FROM    dbo.Request R ,
                    dbo.Request_Row Rr ,
                    dbo.Fighter F
            WHERE   R.RQID = Rr.RQST_RQID
                    AND Rr.FIGH_FILE_NO = F.FILE_NO
                    AND F.FILE_NO = @CardFileNo
                    AND R.RQST_STAT = '001'
                    AND R.RQTP_CODE = '016'
                    AND R.RQTT_CODE = '001';
            
            UPDATE dbo.Card_Link_Operation
               SET FINE_RQST_RQID = @Rqid
             WHERE CODE = @Code;
            
            DECLARE @CashCode BIGINT;
   
            SELECT  @CashCode = CASH_CODE
            FROM    dbo.Payment
            WHERE   RQST_RQID = @Rqid;
            
            INSERT  INTO dbo.Payment_Detail
            (PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,
            EXPN_CODE ,CODE ,PAY_STAT ,EXPN_PRIC ,EXPN_EXTR_PRCT ,QNTY, PYDT_DESC)
            --VALUES (@CashCode, @Rqid, 1, @ExpnCode, 0, '001', @FineAmntDnrm, 0, 1, @Cmnt);
            SELECT @CashCode, @Rqid, 1, @ExpnCode, 0, '001', c.EXPN_1MIN_AMNT_DNRM, 0, c.FINE_MINT_DNRM, @Cmnt
	           FROM dbo.Card_Link_Operation c
	          WHERE c.CODE = @Code;
	      END 
	      ELSE 
	      BEGIN 
	         -- پایان دادن ماموریت
	         UPDATE dbo.Card_Link_Operation
	            SET VALD_TYPE = '001'
	          WHERE CARD_FILE_NO = @CardFileNo
	            AND VALD_TYPE = '002'
	            AND END_TIME IS NOT NULL;
	         
	         UPDATE a
	            SET a.EXIT_TIME = GETDATE()
	           FROM dbo.Card_Link_Operation c, dbo.Attendance a
	          WHERE c.CODE = @Code
	            AND c.ATTN_CODE = a.CODE;
	      END;
	   END
	   
	COMMIT TRAN [T$LNK_CRDO_P]	 
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1 );
	END CATCH
END
GO
