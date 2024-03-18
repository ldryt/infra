import * as pulumi from "@pulumi/pulumi";
import * as gandi from "@pulumiverse/gandi";

const zone1: string = "ldryt.dev";

const record1 = new gandi.livedns.Record("exampleRecord", {
    zone: zone1,
    type: "A",
    name: "kiwi",
    values: ["192.0.2.1"],
    ttl: 3600,
});
