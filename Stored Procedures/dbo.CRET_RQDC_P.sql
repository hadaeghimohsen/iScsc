SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_RQDC_P]
	@RqrqCode BIGINT,
	@RqtpCode VARCHAR(3),
	@RqttCode VARCHAR(3)
AS
BEGIN
	DECLARE C$DCMT CURSOR FOR
	   SELECT Rd.RDID, Rd.DCMT_DSID, Rd.NEED_TYPE, Rd.ORIG_TYPE, Rd.FRST_NEED
	     FROM Regulation Rg, Request_Requester Rq, Request_Document Rd
	    WHERE Rg.REGL_STAT = '002'
	      AND Rg.TYPE      = '001'
	      AND Rg.YEAR      = Rq.REGL_YEAR
	      AND Rg.CODE      = Rq.REGL_CODE
	      AND Rd.RQRQ_CODE = Rq.CODE
	      AND Rq.RQTP_CODE = @RqtpCode
	      AND Rq.RQTT_CODE = @RqttCode;
	      
	DECLARE @Rdid BIGINT
	       ,@DcmtDsid BIGINT
	       ,@NeedType VARCHAR(3)
	       ,@OrigType VARCHAR(3)
	       ,@FrstNeed VARCHAR(3);
	
	OPEN C$DCMT;
	NEXTC$DCMT:
	FETCH NEXT FROM C$DCMT INTO @Rdid, @DcmtDsid, @NeedType, @OrigType, @FrstNeed;
	
	IF @@FETCH_STATUS <> 0
	   GOTO ENDC$DCMT;
	
	IF NOT EXISTS(
	   SELECT *
	     FROM Request_Document
	    WHERE RQRQ_CODE = @RqrqCode
	      AND DCMT_DSID = @DcmtDsid
	)
	BEGIN
	   INSERT INTO Request_Document (RQRQ_CODE, DCMT_DSID, NEED_TYPE, ORIG_TYPE, FRST_NEED) 
	   VALUES (@RqrqCode, @DcmtDsid, @NeedType, @OrigType, @FrstNeed);
	   
	   DECLARE @NewRdid BIGINT;
	   SELECT @NewRdid = RDID
	     FROM dbo.Request_Document
	    WHERE RQRQ_CODE = @RqrqCode
	      AND DCMT_DSID = @DcmtDsid;
	   
	      	   
	   INSERT INTO dbo.Organ_Document ( SUNT_BUNT_DEPT_ORGN_CODE, SUNT_BUNT_DEPT_CODE , SUNT_BUNT_CODE ,SUNT_CODE ,
	          RQDC_RDID , ODID , NEED_TYPE , STAT )
      SELECT SUNT_BUNT_DEPT_ORGN_CODE, SUNT_BUNT_DEPT_CODE , SUNT_BUNT_CODE , SUNT_CODE , 
             @NewRdid , dbo.GNRT_NVID_U() , NEED_TYPE , STAT
        FROM dbo.Organ_Document
       WHERE RQDC_RDID = @Rdid;	   
	END
	
	
	   
	GOTO NEXTC$DCMT;
	ENDC$DCMT:
	CLOSE C$DCMT;		   
	DEALLOCATE C$DCMT;
	    
END
GO
