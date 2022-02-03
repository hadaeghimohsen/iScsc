SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_TXFE_P]
	-- Add the parameters for the stored procedure here
	@X XML,
	@xRet XML OUTPUT	
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN T$CALC_TXFE_P;	
   	
	   DECLARE @Rqid BIGINT,
	           @CashCode BIGINT,
	           @PymtAmnt BIGINT,
	           @AmntType VARCHAR(3);
	   SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
   	
   	-- 1400/01/23 * اگر درخواست جدول هزینه نداشته باشد خروجی مثبت میباشد
   	IF NOT EXISTS(SELECT * FROM Payment WHERE RQST_RQID = @Rqid)
   	BEGIN
   	   SET @xRet = (
             SELECT '002' AS '@rsltcode'                    
                FOR XML PATH('Result')
         );
         GOTO L$EndSP;
   	END 
   	
	   -- باید بررسی شود که ایا درخواست قابلیت کسر کارمزد را دارد یا خیر
	   SELECT @PymtAmnt = p.SUM_EXPN_PRIC,
	          @AmntType = p.AMNT_UNIT_TYPE_DNRM,
	          @CashCode = P.CASH_CODE
	     FROM dbo.Payment p
	    WHERE p.RQST_RQID = @Rqid;
   	 
	   -- 1400/01/21 * اگر درخواست توسط کاربر منشی انجام شود باید بررسی کنیم که آیا سیستم بر اساس کسر کارمزدی میباشد یا خیر
      IF UPPER(SUSER_NAME()) NOT IN ( 'APPUSER', 'WEBUSER' )
      BEGIN
         DECLARE @TxfePrct REAL,
                 @TxfeStat VARCHAR(3),
                 @Tfid BIGINT;
         -- آیا پایگاه داده مربوط به محاسبات کارمزد موجود میباشد یا خیر
         IF EXISTS (SELECT name FROM sys.databases WHERE name = N'iRoboTech')
         BEGIN
            -- مشخص کردن وضعیت و درصد کارمزد
            SELECT @TxfeStat = STAT,
                   @TxfePrct = TXFE_PRCT,
                   @Tfid = TFID
              FROM iRoboTech.dbo.V#Transaction_Fee
             WHERE TXFE_TYPE = '009';
            
            DECLARE @ChatId BIGINT,
                    @WletCode BIGINT,
                    @WletAmnt BIGINT;
            -- اگر سیستم بر اساس محاسبه درصد عمل کند بایستی چک کنیم که ایا باشگاه دار اعتبار در کیف پول اعتباری خود دارد یا خیر
            IF @TxfeStat = '002'
            BEGIN
               -- پیدا کردن مدیر باشگاه و کد کیف پول اعتباری
               SELECT @ChatId = sr.CHAT_ID,
                      @WletCode = w.CODE,
                      @WletAmnt = w.AMNT_DNRM
                 FROM iRoboTech.dbo.Service_Robot sr,
                      iRoboTech.dbo.Service_Robot_Group srg,
                      iRoboTech.dbo.Wallet w
                WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
                  AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
                  AND sr.SERV_FILE_NO = w.SRBT_SERV_FILE_NO
                  AND sr.ROBO_RBID = w.SRBT_ROBO_RBID
                  AND sr.ROBO_RBID = 401
                  AND srg.GROP_GPID = 131
                  AND srg.STAT = '002'
                  AND w.WLET_TYPE = '001'; -- کیف پول اعتباری
               
               -- آیا کیف اعتباری فروشنده شارژ دارد یا خیر
               IF @WletAmnt >= ( (@PymtAmnt * @TxfePrct) / 100 )
               BEGIN            
                  -- محاسبه مبلغ فاکتور و کسر کارمزد از کیف پول اعتباری
                  IF NOT EXISTS (
                     SELECT *
                       FROM iRoboTech.dbo.Wallet_Detail wd
                      WHERE wd.WLET_CODE = @WletCode
                        AND wd.TXFE_TFID = @Tfid
                        AND wd.CONF_DESC LIKE dbo.STR_FRMT_U(N'%{0}%', @Rqid)
                  )
                  BEGIN
                     INSERT INTO iRoboTech.dbo.Wallet_Detail ( TXFE_TFID ,WLET_CODE ,CODE ,AMNT_TYPE ,AMNT ,AMNT_DATE ,AMNT_STAT ,CONF_STAT ,CONF_DATE ,CONF_DESC )
                     VALUES ( @Tfid , @WletCode , 0 , @AmntType , ((@PymtAmnt * @TxfePrct) / 100) , GETDATE() , '002' , '002' , GETDATE() , N'کسر کارمزد بخاطر شماره درخواست ' + CAST(@Rqid AS NVARCHAR(30)) );
                     
                     -- ثبت هزینه کارمزد فاکتور فروش
                     INSERT INTO dbo.Payment_Cost ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,CODE ,AMNT ,COST_TYPE ,EFCT_TYPE ,COST_DESC )
                     VALUES (
                                @CashCode , -- PYMT_CASH_CODE - bigint
                                @Rqid , -- PYMT_RQST_RQID - bigint
                                0 , -- CODE - bigint                             
                                ((@PymtAmnt * @TxfePrct) / 100) , -- AMNT - bigint
                                '001' , -- COST_TYPE - varchar(3)
                                '002' , -- EFCT_TYPE - varchar(3)
                                N'کسر ' + CAST(@TxfePrct AS NVARCHAR(3)) + N' % کارمزد / پورسانت بابت ثبت تراکنش های حضوری ، خدمات و پشتیبانی شرکت و کارفرما'  -- COST_DESC - nvarchar(250)
                            );
                     -- خروجی مثبت
                     SET @xRet = (
                         SELECT '002' AS '@rsltcode'
                            FOR XML PATH('Result')
                     );
                  END 
               END 
               ELSE
               BEGIN
                  -- خروجی منفی
                  SET @xRet = (
                      SELECT '001' AS '@rsltcode',
                             N'بخاطر عدم موجودی کیف پول اعتباری قادر به ثبت اطلاعات نستید' AS '@rsltdesc'
                         FOR XML PATH('Result')
                  );
               END 
            END
            ELSE -- نرخ کارمزد مربوط به سیستم غیر فعال باشد
            BEGIN
               -- خروجی مثبت
               SET @xRet = (
                   SELECT '002' AS '@rsltcode',
                          N'سیستم بدون محاسبه کسر کارمزد میباشد' AS '@rsltdesc'
                      FOR XML PATH('Result')
               );
            END  
         END 
         ELSE -- اگر منبع اطلاعاتی مربوط به نرخ کارمزد وجود نداشته باشد
         BEGIN
            -- خروجی مثبت
            SET @xRet = (
                SELECT '002' AS '@rsltcode'
                   FOR XML PATH('Result')
            );
         END 
      END
      ELSE -- اگر کاربر اپلیکیشن یا وب باشد نیازی به ثبت کارمزد نیست
      BEGIN
         -- خروجی مثبت
         SET @xRet = (
             SELECT '002' AS '@rsltcode'
                FOR XML PATH('Result')
         );
      END 
   	
   	L$EndSP:
	   COMMIT TRAN [T$CALC_TXFE_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);	
	   ROLLBACK TRAN [T$CALC_TXFE_P];
	END CATCH
END
GO
