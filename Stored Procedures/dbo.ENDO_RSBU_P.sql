SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ENDO_RSBU_P]
	-- Add the parameters for the stored procedure here
    @X XML
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN ENDO_RSBU_P_TRAN;
            DECLARE @FileNo BIGINT ,
                @AgopCode BIGINT ,
                @Rwno INT ,
                @SetOnDebt BIT ,
                @Rqid BIGINT;
	       
            SELECT  @FileNo = @X.query('/Aggregation_Operation_Detail').value('(Aggregation_Operation_Detail/@fileno)[1]', 'BIGINT') ,
                    @AgopCode = @X.query('/Aggregation_Operation_Detail').value('(Aggregation_Operation_Detail/@agopcode)[1]', 'BIGINT') ,
                    @Rwno = @X.query('/Aggregation_Operation_Detail').value('(Aggregation_Operation_Detail/@rwno)[1]', 'INT') ,
                    @SetOnDebt = @X.query('/Aggregation_Operation_Detail').value('(Aggregation_Operation_Detail/@setondebt)[1]', 'BIT');
            
            -- Local Var
            DECLARE @CashAmnt BIGINT,
                    @PydsAmnt BIGINT,
                    @DpstAmnt BIGINT,
                    @ExpnAmnt BIGINT;
            
            -- 1398/08/27 * اگر هزینه میز بدهکار باشد
            IF @SetOnDebt IS NULL OR @SetOnDebt = ''
            BEGIN
               IF EXISTS(SELECT * FROM dbo.Aggregation_Operation_Detail WHERE AGOP_CODE = @AgopCode AND RWNO = @Rwno AND TOTL_AMNT_DNRM > (CASH_AMNT + POS_AMNT + DPST_AMNT + PYDS_AMNT))
                  SET @SetOnDebt = 1
               ELSE
                  SET @SetOnDebt = 0;               
            END 
            
            -- 1399/11/17 * اگر مشتری دارای شارژ سپرده باشد مبلغ بدهی راه در نظر نگیرد
            SELECT @ExpnAmnt = EXPN_PRIC, 
                   @DpstAmnt = f.DPST_AMNT_DNRM
              FROM dbo.Aggregation_Operation_Detail a, dbo.Fighter f
             WHERE a.AGOP_CODE = @AgopCode
               AND a.FIGH_FILE_NO = @FileNo
               AND f.FILE_NO = @FileNo;
             
            IF (@DpstAmnt) > 0 AND (@ExpnAmnt >= @DpstAmnt)
            BEGIN
               SET @SetOnDebt = 0;
               UPDATE dbo.Aggregation_Operation_Detail
                  SET PYDS_AMNT += EXPN_PRIC - @DpstAmnt,
                      DPST_AMNT = @DpstAmnt
               WHERE AGOP_CODE = @AgopCode
                 AND FIGH_FILE_NO = @FileNo;
            END 
            
            IF @SetOnDebt = 1
            BEGIN
                /*IF EXISTS ( SELECT  *
                            FROM    dbo.Aggregation_Operation_Detail a
                            WHERE   a.AGOP_CODE = @AgopCode
                                    AND a.RWNO = @Rwno
                                    /*AND (
                                          (
                                            a.CUST_NAME IS NOT NULL
                                            AND a.CUST_NAME != ''
                                          )
                                          OR EXISTS ( /* اطلاعات مشتری قدیمی باشد نه مهمان آزاد */ SELECT
                                                              *
                                                              FROM
                                                              dbo.Fighter f
                                                              WHERE
                                                              f.FILE_NO = a.FIGH_FILE_NO
                                                              AND f.FGPB_TYPE_DNRM != '005' )
                                        )*/ )*/
                BEGIN
                    DECLARE @CellPhon VARCHAR(11) ,
                        @SameFileNo BIGINT;
                    SELECT  @CellPhon = CELL_PHON
                    FROM    dbo.Aggregation_Operation_Detail
                    WHERE   AGOP_CODE = @AgopCode
                            AND RWNO = @Rwno;
         
         -- اگر شماره همراه وارد شده باشد
                    IF @CellPhon IS NOT NULL
                        AND @CellPhon != ''
                        AND ( SELECT    COUNT(*)
                              FROM      dbo.Fighter
                              WHERE     CELL_PHON_DNRM = @CellPhon
                            ) = 1
                    BEGIN
                        SELECT  @SameFileNo = FILE_NO
                        FROM    dbo.Fighter
                        WHERE   CELL_PHON_DNRM = @CellPhon;
            
                        UPDATE  dbo.Aggregation_Operation_Detail
                        SET     FIGH_FILE_NO = @SameFileNo
                        WHERE   AGOP_CODE = @AgopCode
                                AND RWNO = @Rwno;
            
                        SET @FileNo = @SameFileNo;
                    END;
                    ELSE IF @CellPhon IS NOT NULL
                        AND @CellPhon != ''
                        AND ( SELECT    COUNT(*)
                              FROM      dbo.Fighter
                              WHERE     CELL_PHON_DNRM = @CellPhon
                            ) > 1
                    BEGIN
						RAISERROR(N'برای شماره همراه وارد شده چندین مشتری پیدا شد!! لطفا اطلاعات مشتریان خود را بررسی بفرمایید و در صورت تکراری بودن اطلاعات انها را ویرایش کنید', 16, 1);
						RETURN;
                    END 
                    ELSE
                        IF EXISTS ( /* اطلاعات مشتری قدیمی باشد نه مهمان آزاد */ SELECT
                                                              *
                                                              FROM
                                                              dbo.Fighter f ,
                                                              dbo.Aggregation_Operation_Detail a
                                                              WHERE
                                                              f.FILE_NO = a.FIGH_FILE_NO
                                                              AND f.FGPB_TYPE_DNRM != '005'
                                                              AND a.AGOP_CODE = @AgopCode
                                                              AND a.RWNO = @Rwno )
                        BEGIN
			-- پیدا کردن شماره پرونده مشتری قدیمی
                            SELECT  @FileNo = FILE_NO
                            FROM    dbo.Fighter f ,
                                    dbo.Aggregation_Operation_Detail a
                            WHERE   f.FILE_NO = a.FIGH_FILE_NO
                                    AND a.AGOP_CODE = @AgopCode
                                    AND a.RWNO = @Rwno;
                        END; 
                        ELSE
                        BEGIN
							-- 1398/08/23 * شماره تلفن برای ثبت بدهی در مشتری مهمان لازم و ضروری میباشد
							IF NOT EXISTS(
								   SELECT * 
								     FROM dbo.Aggregation_Operation_Detail a
								    WHERE a.CELL_PHON IS NOT NULL
								      AND LEN(a.CELL_PHON) > 0
								      AND a.AGOP_CODE = @AgopCode
								      AND a.RWNO = @Rwno
								   )
							BEGIN
								RAISERROR(N'برای فیلد "شماره همراه" اطلاعات وارد نشده', 16, 1);
								RETURN;
							END 
                            SELECT  @X = ( SELECT   '025' AS '@rqtpcode' ,
                                                    '004' AS '@rqttcode' ,
                                                    '017' AS '@prvncode' ,
                                                    '001' AS '@regncode' ,
                                                    '0' AS '@rqid' ,
                                                    ( SELECT  N'آقای' AS 'Last_Name' ,
                                                              ISNULL(CUST_NAME,
                                                              '') AS 'Frst_Name' ,
                                                              ISNULL(CELL_PHON,
                                                              '') AS 'Cell_Phon'
                                                      FROM    dbo.Aggregation_Operation_Detail
                                                      WHERE   AGOP_CODE = @AgopCode
                                                              AND RWNO = @Rwno
                                                    FOR
                                                      XML PATH('Fighter') ,
                                                          TYPE
                                                    )
                                         FOR
                                           XML PATH('Request') ,
                                               ROOT('Process') ,
                                               TYPE
                                         );
            
                            EXEC dbo.BYR_TRQT_P @X = @X; -- xml
            
                            SELECT TOP 1
                                    @FileNo = f.FILE_NO ,
                                    @Rqid = r.RQID
                            FROM    Request r ,
                                    dbo.Request_Row rr ,
                                    dbo.Fighter f
                            WHERE   r.RQID = rr.RQST_RQID
                                    AND rr.FIGH_FILE_NO = f.FILE_NO
                                    AND r.RQTP_CODE = '025'
                                    AND rr.RQTT_CODE = '004'
                                    AND r.REGN_CODE = '001'
                                    AND r.REGN_PRVN_CODE = '017'
                                    AND r.RQST_STAT = '001'
                                    AND r.CRET_BY = UPPER(SUSER_NAME())
                            ORDER BY r.RQST_DATE DESC;
             
                            SELECT  @X = ( SELECT   @Rqid AS '@rqid' ,
                                                    '017' AS 'prvncode' ,
                                                    '001' AS 'regncode' ,
                                                    ( SELECT  @FileNo AS '@fileno'
                                                    FOR
                                                      XML PATH('Fighter') ,
                                                          TYPE
                                                    )
                                         FOR
                                           XML PATH('Request') ,
                                               ROOT('Process') ,
                                               TYPE
                                         );
             
                            EXEC dbo.BYR_TSAV_F @X = @X; -- xml
             
                            UPDATE  dbo.Aggregation_Operation_Detail
                            SET     FIGH_FILE_NO = @FileNo
                            WHERE   AGOP_CODE = @AgopCode
                                    AND RWNO = @Rwno;
                        END;
                END;
            END; -- IF @SetOnDebt = 1
   
            SELECT  @X = ( SELECT   0 AS '@rqid' ,
                                    '016' AS '@rqtpcode' ,
                                    '007' AS '@rqttcode' ,
                                    ( SELECT    @FileNo AS '@fileno'
                                    FOR
                                      XML PATH('Request_Row') ,
                                          TYPE
                                    )
                         FOR
                           XML PATH('Request') ,
                               ROOT('Process') ,
                               TYPE
                         );
   
            EXEC dbo.OIC_ERQT_F @X = @X; -- xml
   
            SELECT  @Rqid = R.RQID
            FROM    dbo.Request R ,
                    dbo.Request_Row Rr ,
                    dbo.Fighter F
            WHERE   R.RQID = Rr.RQST_RQID
                    AND Rr.FIGH_FILE_NO = F.FILE_NO
                    AND F.FILE_NO = @FileNo
                    AND R.RQST_STAT = '001'
                    AND R.RQTP_CODE = '016'
                    AND R.RQTT_CODE = '007';
   
            DECLARE @CashCode BIGINT;
   
            SELECT  @CashCode = CASH_CODE
            FROM    dbo.Payment
            WHERE   RQST_RQID = @Rqid;
   
   -- درج هزینه میز
            INSERT  INTO dbo.Payment_Detail
                    (
                      PYMT_CASH_CODE ,
                      PYMT_RQST_RQID ,
                      RQRO_RWNO ,
                      EXPN_CODE ,
                      CODE ,
                      PAY_STAT ,
                      EXPN_PRIC ,
                      EXPN_EXTR_PRCT ,
                      QNTY
                    )
                    SELECT  @CashCode ,
                            @Rqid ,
                            1 ,
                            EXPN_CODE ,
                            dbo.GNRT_NVID_U() ,
                            '001' ,
                            EXPN_PRIC * NUMB ,
                            EXPN_EXTR_PRCT * NUMB ,
                            1
                    FROM    dbo.Aggregation_Operation_Detail
                    WHERE   AGOP_CODE = @AgopCode
                            AND RWNO = @Rwno
                            AND FIGH_FILE_NO = @FileNo
                            AND EXPN_CODE IS NOT NULL;
   
   -- درج هزینه بوفه
            INSERT  INTO dbo.Payment_Detail
                    (
                      PYMT_CASH_CODE ,
                      PYMT_RQST_RQID ,
                      RQRO_RWNO ,
                      EXPN_CODE ,
                      CODE ,
                      PAY_STAT ,
                      EXPN_PRIC ,
                      EXPN_EXTR_PRCT ,
                      QNTY
                    )
                    SELECT  @CashCode ,
                            @Rqid ,
                            1 ,
                            B.EXPN_CODE ,
                            dbo.GNRT_NVID_U() ,
                            '001' ,
                            E.PRIC ,
                            E.EXTR_PRCT ,
                            B.QNTY
                    FROM    dbo.Buffet B ,
                            dbo.Expense E
                    WHERE   APDT_AGOP_CODE = @AgopCode
                            AND APDT_RWNO = @Rwno
                            AND B.EXPN_CODE = E.CODE;
   
   -- 1396/2/11
   -- ثبت مبلغ های پرداخت شده
   -- ابتدا مبلغ نقدی
            SELECT  @CashAmnt = ISNULL(CASH_AMNT, 0) ,
                    @PydsAmnt = ISNULL(PYDS_AMNT, 0) ,
                    @DpstAmnt = ISNULL(DPST_AMNT, 0)
            FROM    dbo.Aggregation_Operation_Detail
            WHERE   AGOP_CODE = @AgopCode
                    AND RWNO = @Rwno;
            
            -- ثبت مبلغ نقدی           
            IF @CashAmnt <> 0
                INSERT  INTO dbo.Payment_Row_Type(APDT_AGOP_CODE ,APDT_RWNO ,CODE ,AMNT ,RCPT_MTOD ,ACTN_DATE )
                VALUES  (@AgopCode ,@Rwno , 0 , @CashAmnt , '001' , GETDATE());
            
            -- ثبت مبلغ سپرده
            IF @DpstAmnt <> 0
                INSERT  INTO dbo.Payment_Row_Type(APDT_AGOP_CODE ,APDT_RWNO ,CODE ,AMNT ,RCPT_MTOD ,ACTN_DATE )
                VALUES  (@AgopCode , @Rwno ,0 , @DpstAmnt , '005' , GETDATE());
   
   -- مرحله دوم مبلغ کارتی
   --DECLARE @PosAmnt BIGINT;
   --SELECT @PosAmnt = ISNULL(POS_AMNT,0)
   --  FROM dbo.Aggregation_Operation_Detail
   -- WHERE AGOP_CODE = @AgopCode
   --   AND RWNO = @Rwno;
   
   --IF @PosAmnt <> 0
   --   INSERT INTO dbo.Payment_Row_Type
   --           ( APDT_AGOP_CODE ,
   --             APDT_RWNO ,
   --             CODE ,
   --             AMNT ,
   --             RCPT_MTOD ,
   --             ACTN_DATE 
   --           )
   --   VALUES  ( @AgopCode , -- APDT_AGOP_CODE - bigint
   --             @Rwno , -- APDT_RWNO - int
   --             0 , -- CODE - bigint
   --             @CashAmnt , -- AMNT - bigint
   --             '003' , -- RCPT_MTOD - varchar(3)
   --             GETDATE()  -- ACTN_DATE - datetime
   --           );
   
      
   -- درج پرداختی ها و تخفیف ها
            DECLARE C$Paym CURSOR
            FOR
            SELECT  AMNT ,
                    ACTN_DATE ,
                    RCPT_MTOD
            FROM    dbo.Payment_Row_Type
            WHERE   APDT_AGOP_CODE = @AgopCode
                    AND APDT_RWNO = @Rwno
                    AND RCPT_MTOD NOT IN ( '006' );
   
            DECLARE @Amnt BIGINT ,
                @ActnDate DATE ,
                @RcptMtod VARCHAR(3);
            OPEN C$Paym;
            L$O$C$PAYM:
            FETCH NEXT FROM C$Paym INTO @Amnt, @ActnDate, @RcptMtod;
   
            IF @@FETCH_STATUS <> 0
                GOTO L$C$C$PAYM;
   
            SELECT  @X = ( SELECT   'InsertUpdate' AS '@actntype' ,
                                    ( SELECT    ( SELECT    @CashCode AS '@cashcode' ,
                                                            @Rqid AS '@rqstrqid' ,
                                                            @Amnt AS '@amnt' ,
                                                            @RcptMtod AS '@rcptmtod'
                                                FOR
                                                  XML PATH('Payment_Method') ,
                                                      TYPE
                                                )
                                    FOR
                                      XML PATH('Insert') ,
                                          TYPE
                                    )
                         FOR
                           XML PATH('Payment') ,
                               TYPE
                         );   
   
            EXEC dbo.PAY_MSAV_P @X = @X; -- xml   
   
            GOTO L$O$C$PAYM;
            L$C$C$PAYM:
            CLOSE C$Paym;
            DEALLOCATE C$Paym;
   
   -- درج تخفیف ها
            --DECLARE C$Pyds CURSOR
            --FOR
            --SELECT  AMNT ,
            --        ACTN_DATE ,
            --        RCPT_MTOD
            --FROM    dbo.Payment_Row_Type
            --WHERE   APDT_AGOP_CODE = @AgopCode
            --        AND APDT_RWNO = @Rwno
            --        AND RCPT_MTOD IN ( '006', '005' );
   
            --OPEN C$Pyds;
            --L$O$C$Pyds:
            --FETCH NEXT FROM C$Pyds INTO @Amnt, @ActnDate, @RcptMtod;
   
            --IF @@FETCH_STATUS <> 0
            --    GOTO L$C$C$Pyds;
   
            --EXEC dbo.INS_PYDS_P @PymtCashCode = @CashCode, -- bigint
            --    @PymtRqstRqid = @Rqid, -- bigint
            --    @RqroRwno = 1, -- smallint
            --    @ExpnCode = NULL, -- bigint
            --    @Amnt = @Amnt, -- int
            --    @AmntType = '', -- varchar(3)
            --    @Stat = NULL, -- varchar(3)
            --    @PydsDesc = N'تخفیف بعد از تسویه'; -- nvarchar(250)   
   
            --GOTO L$O$C$Pyds;
            --L$C$C$Pyds:
            --CLOSE C$Pyds;
            --DEALLOCATE C$Pyds;
   
            IF @PydsAmnt > 0
                EXEC dbo.INS_PYDS_P @Pymt_Cash_Code = @CashCode, -- bigint
                    @Pymt_Rqst_Rqid = @Rqid, -- bigint
                    @Rqro_Rwno = 1, -- smallint
                    @Expn_Code = NULL, -- bigint
                    @Amnt = @PydsAmnt, -- int
                    @Amnt_Type = '', -- varchar(3)
                    @Stat = NULL, -- varchar(3)
                    @Pyds_Desc = NULL; -- nvarchar(250)   
   --
   -- مشخص کردن هزینه به صورت تسویه حساب یا ثبت بدهی و دفتری
            DECLARE @TotlAmntDnrm BIGINT;
            SELECT  @TotlAmntDnrm = TOTL_AMNT_DNRM
            FROM    dbo.Aggregation_Operation_Detail
            WHERE   AGOP_CODE = @AgopCode
                    AND RWNO = @Rwno
                    AND FIGH_FILE_NO = @FileNo;
   
            DECLARE @Paym BIGINT ,
                @Pyds BIGINT;
   
            --SELECT  @Paym = SUM(AMNT)
            --FROM    dbo.Payment_Row_Type
            --WHERE   APDT_AGOP_CODE = @AgopCode
            --        AND APDT_RWNO = @Rwno
            --        AND RCPT_MTOD NOT IN ( '006', '005' );
   
            --SELECT  @Pyds = SUM(AMNT)
            --FROM    dbo.Payment_Row_Type
            --WHERE   APDT_AGOP_CODE = @AgopCode
            --        AND APDT_RWNO = @Rwno
            --        AND RCPT_MTOD IN ( '006' );
            SELECT @Paym = POS_AMNT + CASH_AMNT + DPST_AMNT
                  ,@Pyds = PYDS_AMNT
              FROM dbo.Aggregation_Operation_Detail
             WHERE AGOP_CODE = @AgopCode
               AND RWNO = @Rwno;
   
   -- تسویه حساب به صورت کامل
            IF ( ISNULL(@Paym, 0) + ISNULL(@Pyds, 0) ) = ISNULL(@TotlAmntDnrm,
                                                              0)
                SELECT  @X = ( SELECT   @Rqid AS '@rqid' ,
                                        ( SELECT    @FileNo AS '@fileno' ,
                                                    1 AS '@rwno'
                                        FOR
                                          XML PATH('Request_Row') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    0 AS '@setondebt'
                                        FOR
                                          XML PATH('Payment') ,
                                              TYPE
                                        )
                             FOR
                               XML PATH('Request') ,
                                   ROOT('Process') ,
                                   TYPE
                             );
            ELSE -- ثبت به صورت بدهی
                SELECT  @X = ( SELECT   @Rqid AS '@rqid' ,
                                        ( SELECT    @FileNo AS '@fileno' ,
                                                    1 AS '@rwno'
                                        FOR
                                          XML PATH('Request_Row') ,
                                              TYPE
                                        ) ,
                                        ( SELECT    1 AS '@setondebt'
                                        FOR
                                          XML PATH('Payment') ,
                                              TYPE
                                        )
                             FOR
                               XML PATH('Request') ,
                                   ROOT('Process') ,
                                   TYPE
                             );
  
            EXEC dbo.OIC_ESAV_F @X = @X; -- xml
  
            UPDATE  dbo.Aggregation_Operation_Detail
            SET     STAT = '002' ,
                    RQST_RQID = @Rqid
            WHERE   AGOP_CODE = @AgopCode
                    AND RWNO = @Rwno;
     
            COMMIT TRAN ENDO_RSBU_P_TRAN;
        END TRY
        BEGIN CATCH
            IF ( SELECT CURSOR_STATUS('local', 'C$Pyds')
               ) >= -1
            BEGIN
                IF ( SELECT CURSOR_STATUS('local', 'C$Pyds')
                   ) > -1
                BEGIN
                    CLOSE C$Pyds;
                END;
                DEALLOCATE C$Pyds;
            END;
            IF ( SELECT CURSOR_STATUS('local', 'C$Paym')
               ) >= -1
            BEGIN
                IF ( SELECT CURSOR_STATUS('local', 'C$Paym')
                   ) > -1
                BEGIN
                    CLOSE C$Paym;
                END;
                DEALLOCATE C$Paym;
            END;
      
            DECLARE @ErrorMessage NVARCHAR(MAX);
            SET @ErrorMessage = ERROR_MESSAGE();
            RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
            ROLLBACK TRAN ENDO_RSBU_P_TRAN;
        END CATCH;   
    END;
GO
