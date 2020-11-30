SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#SubSys] AS
   SELECT *
     FROM iProject.DataGuard.Sub_System
    WHERE SUB_SYS = 5;
GO
