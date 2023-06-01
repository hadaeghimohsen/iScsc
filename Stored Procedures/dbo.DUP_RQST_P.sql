SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_RQST_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN T$DUP_RQST_P;
	   DECLARE @Type VARCHAR(50),
	           @Rqid BIGINT;
	   
	   SELECT @Type = @X.query('//Duplicate').value('(Duplicate/@type)[1]', 'VARCHAR(50)'),
	          @Rqid = @X.query('//Duplicate').value('(Duplicate/@rqid)[1]', 'VARCHAR(50)');
	   
	   -- Local Var
	   DECLARE @RqtpCode VARCHAR(3),
	           @NewFngrPrnt VARCHAR(20),
	           @NewRqid BIGINT,
	           @NewFileNo BIGINT;	   
	   
	   IF @Type = 'SetInitRecord' 
	   BEGIN
	      UPDATE dbo.Request_Duplicate
	         SET STAT = '001'
	      WHERE CRET_BY = UPPER(SUSER_NAME())
	        AND RQST_RQID != @Rqid
	        AND STAT = '002';
	     
	      INSERT INTO dbo.Request_Duplicate ( RQST_RQID ,CODE )
	      VALUES (@Rqid, 0);	      
	   END
	   ELSE IF @Type = 'copy'
	   BEGIN
	      SELECT @RqtpCode = r.RQTP_CODE,
	             @Rqid = r.RQID
	        FROM dbo.Request r, dbo.Request_Duplicate rd
	       WHERE r.RQID = rd.RQST_RQID
	         AND rd.STAT = '002'
	         AND rd.CRET_BY = UPPER(SUSER_NAME());
	      
	      SELECT @NewFngrPrnt = @X.query('//Duplicate').value('(Duplicate/@fngrprnt)[1]', 'VARCHAR(50)');
	      
	      -- 1402/02/27 * امروز اون هدیه ای که چند روز پیش سفارش داده بودم بدستم رسید و بردم برای خانم راشدی بردم (هدیه روز دختر بود) 
	      -- که بهش بدم گفتم شاید خوشحال بشه از هدیه ام ولی خوب ورق یه جور دیگه زده شد
	      -- در کل امروز میشد یه خرده بهتر جلو میرفت ولی خوب نشد شاید کلا هدیه ام چیز جذابی براش نبود
	      
	      IF @RqtpCode = '001'
	      BEGIN
	         SET @X = (
	             SELECT 0 AS '@rqid',
	                    r.RQTP_CODE AS '@rqtpcode',
	                    r.RQTT_CODE AS '@rqttcode',
	                    (
	                       SELECT 0 AS '@fileno',
	                              (
	                                 SELECT fp.FRST_NAME AS 'Frst_Name',
	                                        fp.LAST_NAME AS 'Last_Name',
	                                        fp.FATH_NAME AS 'Fath_Name',
	                                        fp.SEX_TYPE AS 'Sex_Type',
	                                        fp.NATL_CODE AS 'Natl_Code',
	                                        fp.BRTH_DATE AS 'Brth_Date',
	                                        fp.CELL_PHON AS 'Cell_Phon',
	                                        fp.TELL_PHON AS 'Tell_Phon',
	                                        fp.[TYPE] AS 'Type',
	                                        fp.POST_ADRS AS 'Post_Adrs',
	                                        fp.EMAL_ADRS AS 'Emal_Adrs',
	                                        fp.INSR_NUMB AS 'Insr_Numb',
	                                        fp.INSR_DATE AS 'Insr_Date',
	                                        fp.EDUC_DEG AS 'Educ_Deg',
	                                        fp.CBMT_CODE AS 'Cbmt_Code',
	                                        fp.DISE_CODE AS 'Dise_Code',
	                                        fp.BLOD_GROP AS 'Blod_Grop',
	                                        @NewFngrPrnt AS 'Fngr_Prnt',
	                                        fp.SUNT_BUNT_DEPT_ORGN_CODE AS 'Sunt_Bunt_Dept_Orgn_Code',
	                                        fp.SUNT_BUNT_DEPT_CODE AS 'Sunt_Bunt_Dept_Code',
	                                        fp.SUNT_BUNT_CODE AS 'Sunt_Bunt_Code',
	                                        fp.SUNT_CODE AS 'Sunt_Code',
	                                        fp.CORD_X AS 'Cord_X',
	                                        fp.CORD_Y AS 'Cord_Y',
	                                        fp.GLOB_CODE AS 'Glob_Code',
	                                        fp.CHAT_ID AS 'Chat_Id',
	                                        fp.CTGY_CODE AS 'Ctgy_Code',
	                                        fp.MOST_DEBT_CLNG AS 'Most_Debt_Clng',
	                                        fp.SERV_NO AS 'Serv_No',
	                                        fp.REF_CODE AS 'Ref_Code'
	                                   FROM dbo.Fighter_Public fp
	                                  WHERE fp.RQRO_RQST_RQID = r.RQID
	                                    AND fp.RECT_CODE = '004'
	                                    FOR XML PATH('Fighter'), TYPE	                              
	                              )
	                         FOR XML PATH('Fighter'), TYPE	                       
	                    ),
	                    (
	                       SELECT CAST(ms.STRT_DATE AS DATE) AS '@strtdate',
	                              CAST(ms.END_DATE AS DATE) AS '@enddate',
	                              ms.NUMB_MONT_OFER AS '@numbmontofer',
	                              ms.NUMB_OF_ATTN_WEEK AS '@numbofattnweek',
	                              ms.NUMB_OF_ATTN_MONT AS '@numbofattnmont',
	                              ms.ATTN_DAY_TYPE AS '@attndaytype',
	                              CAST(ms.STRT_DATE AS TIME(0)) AS '@strttime',
	                              CAST(ms.END_DATE AS TIME(0)) AS '@endtime'
	                         FROM dbo.Member_Ship ms
	                        WHERE ms.RQRO_RQST_RQID = r.RQID
	                          AND ms.RECT_CODE = '001'
	                          FOR XML PATH('Member_Ship'), TYPE
	                    )
	               FROM dbo.Request r
	              WHERE r.RQID = @Rqid
	                FOR XML PATH('Request'), ROOT('Process')	                
	         );     
	         EXEC dbo.ADM_TRQT_F @X = @X;
	         
	         -- بدست آوردن شماره درخواست جدید برای کارت جدید
	         SELECT @NewRqid = r.RQID,
	                @NewFileNo = rr.FIGH_FILE_NO
	           FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter_Public fp
	          WHERE r.RQID = rr.RQST_RQID
	            AND rr.RQST_RQID = fp.RQRO_RQST_RQID
	            AND rr.FIGH_FILE_NO = fp.FIGH_FILE_NO
	            AND fp.FNGR_PRNT = @NewFngrPrnt
	            AND fp.RECT_CODE = '001'
	            AND r.RQTP_CODE = @RqtpCode
	            AND r.RQST_STAT = '001'
	            AND CAST(r.RQST_DATE AS DATE) = CAST(GETDATE() AS DATE);
	         
	         -- ثبت درخواست برای ارجاع
	         UPDATE dbo.Request
	            SET RQST_RQID = @Rqid
	          WHERE RQID = @NewRqid;
	         
	         -- ثبت کد تخفیف
	         INSERT INTO dbo.Payment_Discount
            ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,RWNO ,
            FIGH_FILE_NO_DNRM ,PYDT_CODE_DNRM ,EXPN_CODE ,
            AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC ,
            ADVC_CODE ,FGDC_CODE )
            SELECT pds.PYMT_CASH_CODE ,@NewRqid ,pds.RQRO_RWNO ,RWNO ,
                   @NewFileNo ,pd.CODE ,pd.EXPN_CODE ,
                   AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC ,
                   ADVC_CODE ,FGDC_CODE 
              FROM dbo.Payment_Discount pds, dbo.Payment_Detail pd
             WHERE pds.PYMT_RQST_RQID = @Rqid
               AND pd.PYMT_RQST_RQID = @NewRqid;
             
            -- ثبت پرداخت های صورتحساب
	         INSERT INTO dbo.Payment_Method
            ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RQST_RQID ,RQRO_RWNO ,RWNO ,CODE ,
            AMNT ,RCPT_MTOD ,TERM_NO ,TRAN_NO ,CARD_NO ,BANK ,
            FLOW_NO ,REF_NO ,ACTN_DATE ,SHOP_NO ,VALD_TYPE ,RCPT_TO_OTHR_ACNT ,
            RCPT_FILE_PATH )
            SELECT PYMT_CASH_CODE ,@NewRqid ,@NewRqid ,RQRO_RWNO ,0 ,dbo.GNRT_NVID_U() ,
                   AMNT ,RCPT_MTOD ,TERM_NO ,TRAN_NO ,CARD_NO ,BANK ,
                   FLOW_NO ,REF_NO ,ACTN_DATE ,SHOP_NO ,VALD_TYPE ,RCPT_TO_OTHR_ACNT ,
                   RCPT_FILE_PATH
              FROM dbo.Payment_Method pm
             WHERE pm.PYMT_RQST_RQID = @Rqid;
            
            SET @X = (
                SELECT @NewRqid AS '@rqid',
                       (
                          SELECT @NewFileNo AS '@fileno'
                            FOR XML PATH('Fighter'), TYPE                            
                       ),
                       (
                          SELECT 0 AS '@setondebt'
                            FOR XML PATH('Payment'), TYPE                            
                       )
                   FOR XML PATH('Request'), ROOT('Process')
                   
            );
            EXEC dbo.ADM_TSAV_F @X = @X;
	      END 
	      ELSE IF @RqtpCode = '009'
	      BEGIN
	         SET @X = (
	            SELECT 0 AS '@rqid', 
	                   r.RQTP_CODE AS '@rqtpcode',
	                   r.RQTT_CODE AS '@rqttcode',
	                   (
	                      SELECT f.FILE_NO AS '@fileno',
	                             (
	                                SELECT ms.FGPB_CTGY_CODE_DNRM AS '@ctgycodednrm',
	                                       ms.FGPB_CBMT_CODE_DNRM AS '@cbmtcodednrm'
	                                  FROM dbo.Member_Ship ms
	                                 WHERE ms.RQRO_RQST_RQID = r.RQID
	                                   AND ms.RECT_CODE = '004'
	                                   FOR XML PATH('Fighter'), TYPE
	                             ),
	                             (
	                                SELECT CAST(ms.STRT_DATE AS DATE) AS '@strtdate',
	                                       CAST(ms.END_DATE AS DATE) AS '@enddate',
	                                       ms.NUMB_MONT_OFER AS '@numbmontofer',
	                                       ms.NUMB_OF_ATTN_WEEK AS '@numbofattnweek',
	                                       ms.NUMB_OF_ATTN_MONT AS '@numbofattnmont',
	                                       ms.ATTN_DAY_TYPE AS '@attndaytype',
	                                       CAST(ms.STRT_DATE AS TIME(0)) AS '@strttime',
	                                       CAST(ms.END_DATE AS TIME(0)) AS '@endtime'
	                                  FROM dbo.Member_Ship ms
	                                 WHERE ms.RQRO_RQST_RQID = r.RQID
	                                   AND ms.RECT_CODE = '004'
	                                   FOR XML PATH('Member_Ship'), TYPE
	                             )
	                        FROM dbo.Fighter f
	                       WHERE f.FNGR_PRNT_DNRM = @NewFngrPrnt
	                         FOR XML PATH('Request_Row'), TYPE
	                   )
	              FROM dbo.Request r
	             WHERE r.RQID = @Rqid
	               FOR XML PATH('Request'), ROOT('Process')	               
	         );
	         EXEC dbo.UCC_TRQT_P @X = @X;
	         
	         -- بدست آوردن شماره درخواست جدید برای کارت جدید
	         SELECT @NewRqid = r.RQID,
	                @NewFileNo = rr.FIGH_FILE_NO
	           FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f
	          WHERE r.RQID = rr.RQST_RQID
	            AND rr.FIGH_FILE_NO = f.FILE_NO
	            AND f.FNGR_PRNT_DNRM = @NewFngrPrnt
	            AND r.RQTP_CODE = @RqtpCode
	            AND r.RQST_STAT = '001'
	            AND CAST(r.RQST_DATE AS DATE) = CAST(GETDATE() AS DATE);
	         
	         IF @NewRqid IS NULL RAISERROR(N'عدم ثبت درخواست برای کارت، لطفا بررسی کنید که مشتری آزاد باشد', 16, 1);
	         
	         -- ثبت درخواست برای ارجاع
	         UPDATE dbo.Request
	            SET RQST_RQID = @Rqid
	          WHERE RQID = @NewRqid;
	          
	         -- ثبت کد تخفیف
	         INSERT INTO dbo.Payment_Discount
            ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RWNO ,RWNO ,
            FIGH_FILE_NO_DNRM ,PYDT_CODE_DNRM ,EXPN_CODE ,
            AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC ,
            ADVC_CODE ,FGDC_CODE )
            SELECT pds.PYMT_CASH_CODE ,@NewRqid ,pds.RQRO_RWNO ,RWNO ,
                   @NewFileNo ,pd.CODE ,pd.EXPN_CODE ,
                   AMNT ,AMNT_TYPE ,STAT ,PYDS_DESC ,
                   ADVC_CODE ,FGDC_CODE 
              FROM dbo.Payment_Discount pds, dbo.Payment_Detail pd
             WHERE pds.PYMT_RQST_RQID = @Rqid
               AND pd.PYMT_RQST_RQID = @NewRqid;
             
            -- ثبت پرداخت های صورتحساب
	         INSERT INTO dbo.Payment_Method
            ( PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RQST_RQID ,RQRO_RWNO ,RWNO ,CODE ,
            AMNT ,RCPT_MTOD ,TERM_NO ,TRAN_NO ,CARD_NO ,BANK ,
            FLOW_NO ,REF_NO ,ACTN_DATE ,SHOP_NO ,VALD_TYPE ,RCPT_TO_OTHR_ACNT ,
            RCPT_FILE_PATH )
            SELECT PYMT_CASH_CODE ,@NewRqid ,@NewRqid ,RQRO_RWNO ,0 ,dbo.GNRT_NVID_U() ,
                   AMNT ,RCPT_MTOD ,TERM_NO ,TRAN_NO ,CARD_NO ,BANK ,
                   FLOW_NO ,REF_NO ,ACTN_DATE ,SHOP_NO ,VALD_TYPE ,RCPT_TO_OTHR_ACNT ,
                   RCPT_FILE_PATH
              FROM dbo.Payment_Method pm
             WHERE pm.PYMT_RQST_RQID = @Rqid;
            
            SET @X = (
                SELECT @NewRqid AS '@rqid',
                       (
                          SELECT 0 AS '@setondebt'
                             FOR XML PATH('Payment'), TYPE                         
                       )
                   FOR XML PATH('Request'), ROOT('Process') 
            );
            EXEC dbo.UCC_TSAV_P @X = @X;            
	      END 
	      
	      -- ثبت اطلاعات به صورت کامل در سوابق کاربر
	      INSERT INTO dbo.Request_Duplicate ( RQST_RQID ,CODE ,STAT )
	      SELECT @NewRqid, 0,'002'
	        FROM dbo.Request_Duplicate rd
	       WHERE rd.RQST_RQID = @Rqid;
	   END       
	COMMIT TRAN [T$DUP_RQST_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
	ROLLBACK TRAN [T$DUP_RQST_P];
	END CATCH
END
GO
