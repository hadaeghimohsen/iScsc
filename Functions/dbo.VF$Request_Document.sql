SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Request_Document](
   @FileNo BIGINT
)
RETURNS TABLE
AS RETURN
(
SELECT  dbo.Request_Type.CODE, 
        dbo.Request_Type.RQTP_DESC, 
        dbo.Request.RQID, 
        dbo.Request_Row.RWNO,
        dbo.GET_MTOS_U(dbo.Request.RQST_DATE) AS RQST_DATE, 
        dbo.GET_MTOS_U(dbo.Request.SAVE_DATE) AS SAVE_DATE
  FROM  dbo.Request INNER JOIN
        dbo.Request_Row ON dbo.Request.RQID = dbo.Request_Row.RQST_RQID INNER JOIN
        dbo.Request_Type ON dbo.Request.RQTP_CODE = dbo.Request_Type.CODE INNER JOIN        
        dbo.Fighter ON dbo.Request_Row.FIGH_FILE_NO = dbo.Fighter.FILE_NO         
WHERE  (dbo.Request_Row.RECD_STAT = '002') 
  AND  (dbo.Request.RQST_STAT = '002')
  AND  (dbo.Fighter.CONF_STAT = '002')
  AND  (@FileNo IS NULL OR dbo.Fighter.FILE_NO = @FileNo)
  AND  EXISTS(
   SELECT * 
     FROM dbo.Receive_Document 
    WHERE dbo.Request_Row.RQST_RQID = dbo.Receive_Document.RQRO_RQST_RQID 
      AND dbo.Request_Row.RWNO = dbo.Receive_Document.RQRO_RWNO
  )
)
GO
