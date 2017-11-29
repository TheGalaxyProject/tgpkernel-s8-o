#!/system/bin/sh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Mount
mount -o remount,rw /;
mount -o rw,remount /system

# Create init.d folder if not exist
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d
fi

# Apply permissions
	chown -R root.root /system/etc/init.d
	chmod -R 755 /system/etc/init.d

# Execute scripts
for FILE in /system/etc/init.d/*; do
	sh $FILE >/dev/null
done;

