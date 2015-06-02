#version 330 core
in vec3 pos;

uniform mat3 rot_stars;//rotation matrix for the stars
uniform vec3 sun_pos;
uniform sampler2D tint;
uniform sampler2D tint2;
uniform sampler2D sun;
uniform sampler2D moon;
uniform sampler2D clouds1;
uniform sampler2D clouds2;
uniform float weather;
uniform float time;

out vec3 color;

uniform int permutations[256] = int[256](151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23, 190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196, 135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123, 5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42, 223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107, 49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180);


int permutation(int x){
    return permutations[x%256];
}

float f(float x) {
    return 6.0 * x*x*x*x*x - 15.0 * x*x*x*x + 10.0 * x*x*x;
}


float get_grad3(int hash, float x, float y, float z) {
    switch(hash & 0xF){
            case 0x0: return  x + y;
            case 0x1: return -x + y;
            case 0x2: return  x - y;
            case 0x3: return -x - y;
            case 0x4: return  x + z;
            case 0x5: return -x + z;
            case 0x6: return  x - z;
            case 0x7: return -x - z;
            case 0x8: return  y + z;
            case 0x9: return -y + z;
            case 0xA: return  y - z;
            case 0xB: return -y - z;
            case 0xC: return  y + x;
            case 0xD: return -y + z;
            case 0xE: return  y - x;
            case 0xF: return -y - z;
            default: return 0.0; // never happens
        }
}

float noise_p(vec3 pos){
    float ratio = 1.0/ 15.0;//<number of pixels per unit cell (length)
     //Compute coordinates of pixel in cells units
     float x = pos.x / ratio;
     float y = pos.y / ratio;
     float z = pos.z / ratio;
     int j0 = int(x);
     int i0 = int(y);
     int k0 = int(z);
     int i1 = i0 + 1;
     int j1 = j0 + 1;
     int k1 = k0 + 1;

     float f_x = f(x-j0);
     float f_y = f(y-i0);
     float f_z = f(z-k0);

     float x1 = get_grad3(permutation(permutation(j0)+i0)+k0, x-j0 , y-i0  , z-k0);
     float x2 = get_grad3(permutation(permutation(j1)+i0)+k0, x-j1, y-i0 , z-k0);
     float y1 = mix(x1,x2,f_x);
     x1 =  get_grad3(permutation(permutation(j0)+i1)+k0, x-j0  , y-i1, z-k0);
     x2 = get_grad3(permutation(permutation(j1)+i1)+k0, x-j1, y-i1, z-k0   );
     float y2 = mix(x1,x2,f_x);
     float z1 = mix(y1,y2,f_y);
     x1 = get_grad3(permutation(permutation(j0)+i0)+k1, x-j0  , y-i0  , z-k1 );
     x2 = get_grad3(permutation(permutation(j1)+i0)+k1, x-j1, y-i0  , z-k1 );
     y1 = mix(x1,x2,f_x);
     x1 = get_grad3(permutation(permutation(j0)+i1)+k1, x-j0, y-i1, z-k1 );
     x2 = get_grad3(permutation(permutation(j1)+i1)+k1, x-j1, y-i1, z-k1 );
     y2 = mix(x1,x2,f_x);
     float z2 = mix(y1,y2,f_y);

     return mix(z1,z2,f_z);
}

float fBm(vec3 posi){
    float total = 0.0f;
     for(int i = 0; i < 4; i++){
         total += noise_p(posi) * pow(2.0, -1.0 * i);
         posi *= 2.0;
     }
     return total;
}

float Hash( float n ){
        return fract( (1.0 + sin(n)) * 415.92653);
}

//Noise generation based on a simple hash, to ensure that if a given point on the dome
//(after taking into account the rotation of the sky)
//is a star, it remains a star all night long
float Noise3d( vec3 x ){
    float xhash = Hash(round(400*x.x) * 37.0);
    float yhash = Hash(round(400*x.y) * 57.0);
    float zhash = Hash(round(400*x.z) * 67.0);
    return fract(xhash + yhash + zhash);
}



void main(){
    vec3 pos_norm = normalize(pos);
    vec3 sun_norm = normalize(sun_pos);
    float dist = dot(sun_norm,pos_norm);

    //We read the tint texture accoridng to the position of the sun and the weather
    vec3 color_wo_sun = texture(tint2, vec2((sun_norm.y + 1.0) / 2.0,max(0.01,pos_norm.y))).rgb;
    vec3 color_w_sun = texture(tint, vec2((sun_norm.y + 1.0) / 2.0,max(0.01,pos_norm.y))).rgb;
    color = weather*mix(color_wo_sun,color_w_sun,dist*0.5+0.5);

    //Computing u and v for the clouds textures (spherical projection)
    float u = 0.5 + atan(pos_norm.z,pos_norm.x)/(2*3.14159265);
    float v = - 0.5 + asin(pos_norm.y)/3.14159265;

    //Cloud color
    //color depending on the weather (shade of grey) *  day or night ?
    vec3 cloud_color = vec3(min(weather*3.0/2.0,1.0))*(sun_norm.y > 0 ? 0.95 : 0.95+sun_norm.y*1.8);

    //Reading from the clouds maps
    //mixing according to the weather (1.0 -> clouds1 (sunny), 0.5 -> clouds2 (rainy))
    //+ time translation along the u-axis (horizontal)
    float transparency = mix(texture(clouds2,vec2(u+time,v)).r,texture(clouds1,vec2(u+time,v)).r,(weather-0.5)*2.0);

    // Stars
    if(sun_norm.y<0.1){//Night or dawn
        float threshold = 0.99;
        //We genrate a random value between 0 and 1
        float star_intensity = Noise3d(rot_stars * pos_norm);
        //And we apply a threshold to keep only the brightest areas
        if (star_intensity >= threshold){
            //We compute the star intensity
            star_intensity = pow((star_intensity - threshold)/(1.0 - threshold), 6.0)*(-sun_norm.y+0.1);
            color += vec3(star_intensity);
        }
    }

    //Sun
    float radius = length(pos_norm-sun_norm);
    if(radius < 0.05){//We are in the area of the sky which is covered by the sun
        float time = clamp(sun_norm.y,0.01,1);
        radius = radius/0.05;
        if(radius < 1.0-0.001){//< we need a small bias to avoid flickering. Choose it <1/image_size.
            //We read the alpha value from a texture where x = radius and y=height in the sky
            vec4 sun_color = texture(sun,vec2(radius,time));
            color = mix(color,sun_color.rgb,sun_color.a);
        }
    }

    //Moon
    float radius_moon = length(pos_norm+sun_norm);//the moon is at position -sun_pos
    if(radius_moon < 0.03){//We are in the area of the sky which is covered by the moon
        //We define a local plane tangent to the skydome at -sun_norm
        //We work in model space (everything normalized)
        vec3 n1 = normalize(cross(-sun_norm,vec3(0,1,0)));
        vec3 n2 = normalize(cross(-sun_norm,n1));
        //We project pos_norm on this plane
        float x = dot(pos_norm,n1);
        float y = dot(pos_norm,n2);
        //x,y are two sine, ranging approx from 0 to sqrt(2)*0.03. We scale them to [-1,1], then we will translate to [0,1]
        float scale = 23.57*0.5;
        //we need a compensation term because we made projection on the plane and not on the real sphere + other approximations.
        float compensation = 1.4;
        //And we read in the texture of the moon. The projection we did previously allows us to have an undeformed moon
        //(for the sun we didn't care as there are no details on it)
        color = mix(color,texture(moon,vec2(x,y)*scale*compensation+vec2(0.5)).rgb,clamp(-sun_norm.y*3,0,1));
    }

    //Final mix
    //transparency = clamp(fBm(pos*0.5+vec3(0.5,0.5,0.5))*0.5+0.5*0.0,0.0,1.0);
    //mixing with the cloud color allows us to hide things behind clouds (sun, stars, moon)
    color = mix(color,cloud_color,clamp((2-weather)*transparency,0,1));




}
