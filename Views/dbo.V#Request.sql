SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Request] as
SELECT r.*, rr.FIGH_FILE_NO FROM Request r, dbo.Request_Row rr WHERE r.RQID = rr.RQST_RQID AND r.RQST_STAT = '002';
GO