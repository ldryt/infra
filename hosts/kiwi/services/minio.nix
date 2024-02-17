{ config, ... }: {
  virtualisation.oci-containers.containers = {
    "minio" = {
      image =
        "docker.io/minio/minio@sha256:971b368520f677012644eb4884391d6fe3fc39ec60cddaf246a5858ed39843bb";
      entrypoint = "/bin/sh";
      cmd = [ "-c" "mkdir -p /data/ocis-blobs && minio server /data" ];
      environment = {
        MINIO_ACCESS_KEY = "\${MINIO_ACCESS_KEY:?error message}";
        MINIO_SECRET_KEY = "\${MINIO_SECRET_KEY:?error message}";
      };
      environmentFiles =
        [ config.sops.secrets."services/ocis/s3/credentials".path ];
      volumes = [ "/mnt/glouton/minio-buckets:/data" ];
      ports = [ "44061:9000" ];
    };
  };
}
