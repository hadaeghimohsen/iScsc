SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_COMM_P](
   @RQST_RQID BIGINT
  ,@COMM_TYPE VARCHAR(3)
  ,@Cmid      BIGINT OUT
)
AS
BEGIN
   INSERT INTO Committee(
      CMID,
      RQST_RQID,
      COMM_TYPE
   )
   VALUES
   (
      dbo.GNRT_NWID_U(),
      @RQST_RQID,
      @COMM_TYPE
   );
   
   SELECT @Cmid = MAX(Cmid) 
   FROM Committee
   WHERE RQST_RQID = @RQST_RQID
     AND COMM_TYPE = @COMM_TYPE;
   
END;
GO
