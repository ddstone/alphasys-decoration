import sys
import PIL.Image
import io
import base64
import json
import os


SINK_WS_ADDR = "ws://192.168.2.3:5000/websocket"


def parse_by_prefix(sink_path):
    prefix = sink_path.rsplit('/', 1)[1].split('.', 1)[0]
    fid_str, res = prefix.split('_', 1)

    def parse_subset(subset):
        head, gen = subset.rsplit('-', 1)
        x1, y1, x2, y2, age = list(map(lambda x: int(x), head.split('-')))
        return x1, y1, x2, y2, age, gen

    face_infos = list(map(parse_subset, res.split('_')))

    return int(fid_str), face_infos


def main():
    sink_path = sys.argv[1]
    fid, faces = parse_by_prefix(sink_path)
    img = PIL.Image.open(sink_path)

    str2print = ''
    for x1, y1, x2, y2, age, gen in faces:
        face = img.crop((x1, y1, x2, y2))

        face_byte_arr = io.BytesIO()
        face.save(face_byte_arr, format='jpeg')
        face_byte_arr = face_byte_arr.getvalue()
        encoded = base64.b64encode(face_byte_arr)
        encoded_str = 'data:image/jpeg;base64,' \
                      + encoded.decode('utf-8')
        # str2print += f'{age}-{gen}-{encoded_str}|'
        str2print += f'{age}-{gen}-encoded_str|'
        # print(len(encoded_str))

        # print(age, gen)
        # result = {
        #     'Age': age,
        #     'Gender': gen,
        #     'BinData': encoded_str
        # }
        # jresult = json.dumps(result)

    str2print = str2print[:-1]
    os.system(
        f'echo \'{str2print}\''
    )

    # result = None
    # print('Decode!')
    # result1 = json.loads(jresult)
    # age1, gen1 = result1['Age'], result1['Gender']
    # print(age1, gen1)
    # prefix, face1_byte_str = result1['BinData'].split(',', 1)
    # print(prefix)
    # face1_bytes = base64.b64decode(str.encode(face1_byte_str))
    # face1 = PIL.Image.open(io.BytesIO(face1_bytes))
    # face1.show()


if __name__ == '__main__':
    main()
