"""Split broken combined level/on-off commands on this Tuya bulb firmware."""

from zigpy.zcl.clusters.general import LevelControl
from zigpy.zcl.foundation import Status

from zhaquirks.builder import QuirkBuilder
from zhaquirks.clusters import CustomCluster


class SeparateLevelControl(CustomCluster, LevelControl):
    async def command(self, command_id, *args, **kwargs):
        if command_id != 0x04:
            return await super().command(command_id, *args, **kwargs)

        level = kwargs.get("level", args[0] if args else 0)
        if level == 0:
            return await self.endpoint.on_off.off()

        result = await super().command(0x00, *args, **kwargs)
        if result[1] != Status.SUCCESS:
            return result
        return await self.endpoint.on_off.on()


# https://github.com/Koenkk/zigbee-herdsman-converters/pull/12783
(
    QuirkBuilder("_TZ3210_mja6r5ix", "TS0505B")
    .replaces(SeparateLevelControl)
    .add_to_registry()
)
