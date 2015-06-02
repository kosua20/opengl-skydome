#version 330 core
in vec3 vpoint;
in vec3 vnormal;

uniform mat4 mvp;

out vec3 pos;

void main(){
    gl_Position = mvp * vec4(vpoint, 1.0);
    pos = vpoint;
}
