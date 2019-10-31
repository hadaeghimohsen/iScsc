SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[OIC_ESAV_F]
	-- Add the parameters for the stored procedure here
    @X XML
AS
    BEGIN
        DECLARE @AP BIT ,
            @AccessString VARCHAR(250);
        SET @AccessString = N'<AP><UserName>' + SUSER_NAME()
            + '</UserName><Privilege>153</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
        EXEC iProject.dbo.sp_executesql N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',
            N'@P1 ntext, @ap BIT OUTPUT', @AccessString, @ap = @AP OUTPUT;
        IF @AP = 0
            BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 153 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
                RETURN;
            END;

        SET @AccessString = N'<AP><UserName>' + SUSER_NAME()
            + '</UserName><Privilege>154</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
        EXEC iProject.dbo.sp_executesql N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',
            N'@P1 ntext, @ap BIT OUTPUT', @AccessString, @ap = @AP OUTPUT;
        IF @AP = 0
            BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 154 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
                RETURN;
            END;
   
        DECLARE @ErrorMessage NVARCHAR(MAX);
        BEGIN TRAN T$ADM_TSAV_F;
        BEGIN TRY
            DECLARE @Rqid BIGINT ,
                @FileNo BIGINT ,
                @PrvnCode VARCHAR(3) ,
                @RegnCode VARCHAR(3);   	
	          
            SELECT  @Rqid = @X.query('//Request').value('(Request/@rqid)[1]',
                                                        'BIGINT') ,
                    @PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]',
                                                            'VARCHAR(3)') ,
                    @RegnCode = @X.query('//Request').value('(Request/@regncode)[1]',
                                                            'VARCHAR(3)');
	         
            SELECT  @FileNo = FILE_NO
            FROM    Fighter
            WHERE   RQST_RQID = @Rqid;
      
            UPDATE  Payment_Detail
            SET     PAY_STAT = '002' ,
                    RCPT_MTOD = @X.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]',
                                                              'VARCHAR(3)')
            WHERE   PYMT_RQST_RQID = @Rqid
                    AND PAY_STAT = '001'
                    AND @X.query('//Payment').value('(Payment/@setondebt)[1]',
                                                    'BIT') = 0;
      
            UPDATE  Request
            SET     RQST_STAT = '002'
            WHERE   RQID = @Rqid;
      
      -- 1398/06/30 * ثبت پیامک
            IF EXISTS ( SELECT  *
                        FROM    dbo.Message_Broadcast
                        WHERE   MSGB_TYPE = '027'
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
                        @Cel5Phon VARCHAR(11);
                      
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
                    WHERE   MSGB_TYPE = '027';                    
                    
                    IF @MsgbStat = '002'
                        BEGIN
                            IF EXISTS ( SELECT  *
                                        FROM    dbo.Fighter_Public
                                        WHERE   RQRO_RQST_RQID = @Rqid
                                                AND FIGH_FILE_NO = @FileNo
                                                AND RECT_CODE = '001'
                                                AND CELL_PHON IS NOT NULL
                                                AND CELL_PHON != ''
                                                AND LEN(CELL_PHON) >= 10 )
                                BEGIN
                                    SELECT  @CellPhon = CELL_PHON
                                    FROM    dbo.Fighter_Public
                                    WHERE   RQRO_RQST_RQID = @Rqid
                                            AND FIGH_FILE_NO = @FileNo
                                            AND RECT_CODE = '001'
                                            AND CELL_PHON IS NOT NULL
                                            AND CELL_PHON != ''
                                            AND LEN(CELL_PHON) >= 10;
                                    
                                    SELECT  @MsgbText = ( SELECT
                                                              CASE
                                                              WHEN fp.LAST_NAME != ''
                                                              THEN s.DOMN_DESC
                                                              + N' '
                                                              + fp.LAST_NAME
                                                              ELSE N'مهمان عزیز '
                                                              END + CHAR(10)
                                                              + @MsgbText
                                                              + CHAR(10)
                                                              + CASE @InsrCnamStat
                                                              WHEN '002'
                                                              THEN @ClubName
                                                              ELSE N''
                                                              END + CHAR(10)
                                                              + N'شرح فاکتور خدمات'
                                                              + CHAR(10)
                                                              + +( SELECT
                                                              e.EXPN_DESC
                                                              + N' '
                                                              + N' به مبلغ '
                                                              + CAST(pd.EXPN_PRIC AS NVARCHAR(50))
                                                              + CASE
                                                              WHEN pd.EXPR_DATE IS NOT NULL
                                                              THEN N' تا تاریخ اعتبار'
                                                              + dbo.GET_MTOS_U(pd.EXPR_DATE)
                                                              ELSE N''
                                                              END + CHAR(10)
                                                              FROM
                                                              dbo.Payment_Detail pd ,
                                                              dbo.Expense e
                                                              WHERE
                                                              pd.PYMT_RQST_RQID = @Rqid
                                                              AND pd.EXPN_CODE = e.CODE
                                                              FOR
                                                              XML
                                                              PATH('')
                                                              )
                                                          FROM
                                                              dbo.Request r ,
                                                              dbo.Request_Row rr ,
                                                              dbo.Fighter_Public fp ,
                                                              dbo.[D$SXDC] s
                                                          WHERE
                                                              r.RQID = rr.RQST_RQID
                                                              AND rr.RQST_RQID = fp.RQRO_RQST_RQID
                                                              AND rr.RWNO = fp.RQRO_RWNO
                                                              AND rr.FIGH_FILE_NO = fp.FIGH_FILE_NO
                                                              AND fp.SEX_TYPE = s.VALU
                                                              AND rr.FIGH_FILE_NO = @FileNo
                                                              AND r.RQID = @Rqid
                                                        );          
                                    SELECT  @XMsg = ( SELECT  5 AS '@subsys' ,
                                                              @LineType AS '@linetype' ,
                                                              ( SELECT
                                                              @CellPhon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
                                                              TYPE
                                                              ) ,
                                                              ( SELECT
                                                              @Cel1Phon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
                                                              TYPE
                                                              ) ,
                                                              ( SELECT
                                                              @Cel2Phon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
                                                              TYPE
                                                              ) ,
                                                              ( SELECT
                                                              @Cel3Phon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
                                                              TYPE
                                                              ) ,
                                                              ( SELECT
                                                              @Cel4Phon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
                                                              TYPE
                                                              ) ,
                                                              ( SELECT
                                                              @Cel5Phon AS '@phonnumb' ,
                                                              ( SELECT
                                                              '027' AS '@type' ,
                                                              @Rqid AS '@rfid',
                                                              @MsgbText
                                                              FOR
                                                              XML
                                                              PATH('Message') ,
                                                              TYPE
                                                              )
                                                              FOR
                                                              XML
                                                              PATH('Contact') ,
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
      
            COMMIT TRAN T$ADM_TSAV_F;
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = ERROR_MESSAGE();
            RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
            ROLLBACK TRAN T$ADM_TSAV_F;
        END CATCH;
    END;

/****** Object:  Trigger [dbo].[CG$AUPD_MBSP]    Script Date: 09/24/2019 16:53:17 ******/
SET ANSI_NULLS ON
GO
