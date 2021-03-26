SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Request_Changing] ( @FileNo BIGINT )
RETURNS TABLE
    AS RETURN
    ( SELECT    T.RQTP_CODE ,
                T.RQTP_DESC ,
                T.RQTT_CODE ,
                T.RQTT_DESC ,
                T.RQID ,
                T.RQST_RQID ,
                T.RQST_DATE ,
                T.SAVE_DATE ,
                T.CRET_BY ,
                T.RQST_DESC ,
                T.TOTL_AMNT ,
                CASE T.TOTL_AMNT 
                     WHEN 0 THEN 0
                     ELSE                    
                ISNULL(( SELECT SUM(Pm.AMNT)
                         FROM   Payment_Method Pm
                         WHERE  Pm.PYMT_CASH_CODE = T.CASH_CODE
                                AND Pm.PYMT_RQST_RQID = T.PYMT_RQST_RQID
                       ), 0) END AS TOTL_RCPT_AMNT ,
                CASE T.TOTL_AMNT
                     WHEN 0 THEN 0
                     ELSE 
                ISNULL(( SELECT SUM(CAST(pc.AMNT AS BIGINT))
                         FROM   Payment_Discount pc
                         WHERE  pc.PYMT_CASH_CODE = T.CASH_CODE
                                AND pc.PYMT_RQST_RQID = T.PYMT_RQST_RQID
                       ), 0) END AS TOTL_DSCT_AMNT
      FROM      ( SELECT    r.RQTP_CODE ,
                            rqtp.RQTP_DESC ,
                            r.RQTT_CODE ,
                            rqtt.RQTT_DESC ,
                            r.RQID ,
                            r.RQST_RQID ,
                            r.RQST_DATE ,
                            r.SAVE_DATE ,
                            r.RQST_DESC ,
                            r.CRET_BY ,
                            p.RQST_RQID AS PYMT_RQST_RQID ,
                            p.CASH_CODE ,                            
                            ISNULL(SUM(CAST(CASE p.PYMT_STAT WHEN '001' THEN ( pd.EXPN_PRIC
                                         + ISNULL(pd.EXPN_EXTR_PRCT, 0) )
                                       * pd.QNTY ELSE 0 END AS BIGINT)), 0) AS TOTL_AMNT
                  FROM      dbo.Request r
                            INNER JOIN dbo.Request_Row rr ON r.RQID = rr.RQST_RQID
                            INNER JOIN dbo.Request_Type rqtp ON r.RQTP_CODE = rqtp.CODE
                            INNER JOIN dbo.Requester_Type rqtt ON r.RQTT_CODE = rqtt.CODE
                            INNER JOIN dbo.Fighter f ON rr.FIGH_FILE_NO = f.FILE_NO
                            LEFT OUTER JOIN dbo.Payment p ON p.RQST_RQID = r.RQID
                            LEFT OUTER JOIN dbo.Payment_Detail pd ON pd.PYMT_CASH_CODE = p.CASH_CODE
                                                              AND pd.PYMT_RQST_RQID = p.RQST_RQID
                  WHERE     ( rr.RECD_STAT = '002' )
                            AND ( r.RQST_STAT = '002' )
                            AND ( f.CONF_STAT = '002' )
                            AND ( r.RQTP_CODE NOT IN ( '020' ) )
                            AND ( @FileNo IS NULL
                                  OR f.FILE_NO = @FileNo
                                )
                  GROUP BY  r.RQTP_CODE ,
                            rqtp.RQTP_DESC ,
                            r.RQTT_CODE ,
                            rqtt.RQTT_DESC ,
                            r.RQID ,
                            r.RQST_RQID ,
                            r.RQST_DATE ,
                            r.SAVE_DATE ,
                            r.CRET_BY ,
                            r.RQST_DESC ,
                            p.RQST_RQID ,
                            p.CASH_CODE
                ) T
      UNION ALL
      SELECT    r.RQTP_CODE ,
                rt.RQTP_DESC ,
                r.RQTT_CODE ,
                rqt.RQTT_DESC ,
                r.RQID ,
                r.RQST_RQID ,
                r.RQST_DATE ,
                r.SAVE_DATE ,
                r.CRET_BY ,
                r.RQST_DESC ,                
                CASE g.DPST_STAT
                  WHEN '001' THEN -1 * g.AMNT
                  ELSE g.AMNT
                END AS TOTL_AMNT ,
                CASE g.DPST_STAT
                  WHEN '001' THEN -1 * g.AMNT
                  ELSE g.AMNT
                END AS TOTL_RCPT_AMNT ,
                0 AS TOTL_DSCT_AMNT
      FROM      dbo.Request_Type rt ,
                dbo.Requester_Type rqt ,
                dbo.Request r ,
                dbo.Request_Row rr ,
                dbo.Gain_Loss_Rial g
      WHERE     r.RQTP_CODE = '020'
                AND r.RQST_STAT = '002'
                AND rt.CODE = r.RQTP_CODE
                AND rqt.CODE = r.RQTT_CODE
                AND r.RQID = rr.RQST_RQID
                AND rr.RQST_RQID = g.RQRO_RQST_RQID
                AND rr.RWNO = g.RQRO_RWNO
                AND ( 
                      @FileNo IS NULL OR 
                      rr.FIGH_FILE_NO = @FileNo
                    )
    );
GO
